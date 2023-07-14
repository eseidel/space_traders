import 'dart:convert';

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
    this.maxRequestsPerSecond = 3,
    super.authentication,
  });

  /// The number of requests per second to allow.
  final int maxRequestsPerSecond;

  int _backoffSeconds = 1;

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

  /// Reset the backoff, called after a successful request.
  void _resetBackoff() {
    _backoffSeconds = 1;
  }

  /// Used to guess whether the response is from the server (which will always
  /// reply with json) or from some other source (which may not).
  bool _tryParseBody(Response response) {
    try {
      jsonDecode(response.body);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Handle an unexpected rate limit response by waiting and retrying once.
  @visibleForTesting
  Future<Response> handleUnexpectedRateLimit(
    Future<Response> Function() sendRequest, {
    Duration? overrideWaitTime,
  }) async {
    while (true) {
      try {
        final response = await sendRequest();
        // We assume any response < 400 is OK.
        if (response.statusCode < 400) {
          return response;
        }
        // If it's not a 429 (rate limit) response, and we can parse the body,
        // we assume it's a valid error from the server and return it.
        if (response.statusCode != 429 && _tryParseBody(response)) {
          return response;
        }
        // If this is a 429, we could parse the x-ratelimit-reset header and
        // wait until then.
        // final resetTime = _parseResetTime(response);

        // Otherwise we assume it's a transient error and retry.
        logger.warn(
          'Unexpected ${response.statusCode} response: '
          '${response.body}, retrying after $_backoffSeconds seconds',
        );
      } catch (e) {
        // Network errors are transient and we retry.
        logger.warn(
          'Unexpected $e, retrying after $_backoffSeconds seconds',
        );
      }
      // Override the wait time for testing.
      final waitTime = overrideWaitTime ?? Duration(seconds: _backoffSeconds);
      _backoffSeconds *= 2;
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
      await Future<void>.delayed(_nextRequestTime.difference(beforeRequest));
    }
    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';
    logger.detail('$path$queryString');
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
    _resetBackoff();
    return response;
  }
}
