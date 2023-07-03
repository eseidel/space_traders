import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// RequestCounts tracks the number of requests made to each path.
class RequestCounts {
  /// The counts.
  final Map<String, int> counts = {};

  /// Get the number of requests made to the given path.
  void recordRequest(String path) {
    counts[path] = (counts[path] ?? 0) + 1;
  }

  /// Get the total number of requests made.
  int totalRequests() {
    return counts.values.fold(0, (a, b) => a + b);
  }

  /// Reset the counts.
  void reset() {
    counts.clear();
  }
}

// This does not yet support "burst" requests which the api allows.
// This also could hold a queue of recent request times to allow for more
// accurate rate limiting.
/// Rate limiting api client.
class RateLimitedApiClient extends ApiClient {
  /// Construct a rate limited api client.
  RateLimitedApiClient({
    this.maxRequestsPerSecond = 2,
    super.authentication,
  });

  /// The number of requests per second to allow.
  final int maxRequestsPerSecond;

  /// RequestCounts tracks the number of requests made to each path.
  final RequestCounts requestCounts = RequestCounts();

  DateTime _nextRequestTime = DateTime.timestamp();

  // static DateTime? _parseResetTime(Response response) {
  //   final resetString = response.headers['x-ratelimit-reset'];
  //   if (resetString == null) {
  //     return null;
  //   }
  //   return DateTime.parse(resetString);
  // }

  /// Handle an unexpected rate limit response by waiting and retrying once.
  @visibleForTesting
  static Future<Response> handleUnexpectedRateLimit(
    Future<Response> Function() sendRequest, {
    Duration waitTime = const Duration(seconds: 10),
  }) async {
    // TODO(eseidel): This should use exponential back-off or a fixed
    // number of retries for all types of failures, not just 429.
    while (true) {
      final response = await sendRequest();
      if (response.statusCode > 500) {
        logger.warn('${response.statusCode} seen at ${DateTime.now()}');
      }
      if (response.statusCode != 429) {
        return response;
      }
      // Could parse out the reset time from the headers and wait until then.
      logger.warn(
        'Unexpected rate limit response, waiting ${waitTime.inSeconds} '
        'seconds and retrying',
      );
      await Future<void>.delayed(waitTime);
    }
  }

  @override
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    final beforeRequest = DateTime.now();
    if (beforeRequest.isBefore(_nextRequestTime)) {
      // logger.detail(
      //   'Rate limiting request. Next request time: $_nextRequestTime',
      // );
      await Future<void>.delayed(_nextRequestTime.difference(beforeRequest));
    }
    logger.detail('$path');
    final response = await handleUnexpectedRateLimit(
      () async => super.invokeAPI(
        path,
        method,
        queryParams,
        body,
        headerParams,
        formParams,
        contentType,
      ),
    );
    requestCounts.recordRequest(path);
    final afterRequest = DateTime.now();
    _nextRequestTime =
        afterRequest.add(Duration(milliseconds: 1000 ~/ maxRequestsPerSecond));
    return response;
  }
}
