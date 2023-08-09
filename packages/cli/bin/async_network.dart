import 'dart:async';
import 'dart:convert';

import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

class RateLimiter {
  RateLimiter({this.maxRequestsPerSecond = 3});

  /// The number of requests per second to allow.
  final int maxRequestsPerSecond;

  int _backoffSeconds = 1;
  Timer? _timer;
  final List<Completer<void>> _queue = [];
  DateTime _nextRequestTime = DateTime.timestamp();

  int get backoffSeconds => _backoffSeconds;

  Duration get _minWaitTime =>
      Duration(milliseconds: 1000 ~/ maxRequestsPerSecond);

  /// Reset the backoff, called after a successful request.
  void resetBackoff() {
    _backoffSeconds = 1;
  }

  void backoff() {
    _scheduleNextRequestFor(
      DateTime.timestamp().add(Duration(seconds: _backoffSeconds)),
    );
    _backoffSeconds *= 2;
  }

  void _scheduleNextRequestFor(DateTime time) {
    _nextRequestTime = time;
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(time.difference(DateTime.timestamp()), _timerFired);
  }

  void _startTimerIfNeeded() {
    _timer ??= Timer(_minWaitTime, _timerFired);
  }

  void _timerFired() {
    _timer = null;
    final now = DateTime.timestamp();
    // This can happen when we're rate-limited and we get a doubleBackoff
    // call before the timer fires.
    if (now.isBefore(_nextRequestTime)) {
      _scheduleNextRequestFor(_nextRequestTime);
      return;
    }

    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
    }
    if (_queue.isNotEmpty) {
      _timer = Timer(_minWaitTime, _timerFired);
    }
  }

  Future<void> waitForRateLimit() async {
    final completer = Completer<void>();
    _queue.add(completer);
    _startTimerIfNeeded();
    return completer.future;
  }
}

// This does not yet support "burst" requests which the api allows.
// This also could hold a queue of recent request times to allow for more
// accurate rate limiting.
/// Rate limiting api client.
class NewClient extends RateLimitedApiClient {
  /// Construct a rate limited api client.
  NewClient({
    super.maxRequestsPerSecond = 3,
    super.authentication,
  }) : rateLimiter = RateLimiter(maxRequestsPerSecond: maxRequestsPerSecond);

  RateLimiter rateLimiter;

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
  @override
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
      } catch (e) {
        // Network errors are transient and we retry.
      }
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
    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';
    final response = await handleUnexpectedRateLimit(() async {
      await rateLimiter.waitForRateLimit();
      logger.detail('$path$queryString');
      final agent = Agent(
        accountId: 'string',
        symbol: 'string',
        headquarters: 'string',
        credits: 10,
        startingFaction: 'string',
        shipCount: 1,
      );
      final wrapper = GetMyAgent200Response(data: agent);
      final jsonString = jsonEncode(wrapper.toJson());
      requestCounts.recordRequest(path);
      return Future.value(Response(jsonString, 200));
    });
    return response;
  }
}

Future<void> shipOne(Api api) async {
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    await getMyAgent(api);
  }
}

Future<void> shipTwo(Api api) async {
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 2));
    await getMyAgent(api);
    await getMyAgent(api);
  }
}

void startShips(RateLimitedApiClient apiClient) {
  final api = Api(apiClient);
  // ignore: unawaited_futures
  shipOne(api);
  // ignore: unawaited_futures
  shipTwo(api);
}

Future<void> app(FileSystem fs, List<String> args) async {
  setVerboseLogging();
  final apiClient = NewClient();
  startShips(apiClient);
}

void main(List<String> args) {
  runOffline(args, app);
}
