import 'dart:async';
import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/printing.dart';
import 'package:clock/clock.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// Prints stats about rate limiting.
class RateLimitStatPrinter {
  /// Total number of requests since last reset.
  int _total = 0;

  /// Number of successful requests since last reset.
  int _successes = 0;

  /// Number of rate limited requests since last reset.
  int _rateLimits = 0;

  DateTime _lastPrintTime = DateTime.timestamp();

  void _printStatsIfNonZero(Duration duration) {
    if (_total > 0) {
      logger.info(
        '$_successes ($_rateLimits) in '
        '${approximateDuration(duration)} total: $_total',
      );
    }
  }

  void _reset() {
    _total = 0;
    _successes = 0;
    _rateLimits = 0;
  }

  /// Print the stats if it's been at least a minute since the last print.
  void printIfNeeded() {
    final sinceLastPrint = DateTime.timestamp().difference(_lastPrintTime);
    if (sinceLastPrint >= const Duration(minutes: 1)) {
      _printStatsIfNonZero(sinceLastPrint);
      _reset();
      _lastPrintTime = DateTime.timestamp();
    }
  }

  /// Record a response.
  void record(Response response) {
    _total++;
    if (response.statusCode == 429) {
      _rateLimits++;
    } else {
      _successes++;
    }
  }
}

/// A rate limiter that can be used to rate limit requests to the api.
class RateLimiter {
  /// Construct a rate limiter.
  RateLimiter({this.maxRequestsPerSecond = 3});

  /// The number of requests per second to allow.
  final int maxRequestsPerSecond;

  /// Get the current time (in utc).
  static DateTime _now() => clock.now().toUtc();

  int _backoffSeconds = 1;
  Timer? _timer;
  final List<Completer<void>> _queue = [];
  DateTime _nextRequestTime = _now();
  bool _requestInProgress = false;

  /// The current backoff in seconds.
  int get backoffSeconds => _backoffSeconds;

  Duration get _minWaitTime =>
      Duration(milliseconds: 1000 ~/ maxRequestsPerSecond);

  /// Reset the backoff, called after a successful request.
  void requestCompleted() {
    _requestInProgress = false;
    _nextRequestTime = _now().add(_minWaitTime);
    _backoffSeconds = 1;
  }

  /// Backoff for the current backoff time.
  void requestCameBackRateLimited({Duration? overrideWaitTime}) {
    _requestInProgress = false;
    final waitTime = overrideWaitTime ?? Duration(seconds: _backoffSeconds);
    final nextRequestTime = _now().add(waitTime);
    _scheduleNextRequestFor(nextRequestTime);
    _backoffSeconds *= 2;
  }

  void _scheduleNextRequestFor(DateTime time) {
    _nextRequestTime = time;
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(time.difference(_now()), _timerFired);
  }

  void _startTimerIfNeeded() {
    _timer ??= Timer(_minWaitTime, _timerFired);
  }

  void _timerFired() {
    _timer = null;
    // This can happen when we're rate-limited and we get a doubleBackoff
    // call before the timer fires.
    if (_now().isBefore(_nextRequestTime)) {
      _scheduleNextRequestFor(_nextRequestTime);
      return;
    }

    // If we still have a request in progress, we wait for it to complete
    // before allowing any more requests.
    if (_requestInProgress) {
      logger.warn('Request took longer than expected, waiting again.');
      _startTimerIfNeeded();
      return;
    }

    // If there are more requests in the queue, we allow the next one to go.
    if (_queue.isNotEmpty) {
      _requestInProgress = true;
      _queue.removeAt(0).complete();
    }
    // If there are still more requests in the queue, we start the timer again
    // to allow the next one to go.
    if (_queue.isNotEmpty) {
      _timer = Timer(_minWaitTime, _timerFired);
    }
  }

  /// Wait for the next request to be allowed.
  Future<void> waitForRateLimit() async {
    // If we have no request in progress and nothing is waiting, we can
    // immediately return.
    if (!_requestInProgress &&
        _queue.isEmpty &&
        _now().isAfter(_nextRequestTime)) {
      _requestInProgress = true;
      // _nextRequestTime will be updated when the request completes.
      return Future.value();
    }
    // Otherwise we queue up a completer and wait for the timer to fire.
    final completer = Completer<void>();
    _queue.add(completer);
    _startTimerIfNeeded();
    return completer.future;
  }
}

/// A function that can be used to invoke the api.
typedef InvokeApi = Future<Response> Function(
  String path,
  String method,
  List<QueryParam> queryParams,
  Object? body,
  Map<String, String> headerParams,
  Map<String, String> formParams,
  String? contentType,
);

// This does not yet support "burst" requests which the api allows.
// This also could hold a queue of recent request times to allow for more
// accurate rate limiting.
/// Rate limiting api client.
class RateLimitedApiClient extends CountingApiClient {
  /// Construct a rate limited api client.
  RateLimitedApiClient({
    int maxRequestsPerSecond = 3,
    super.authentication,
    @visibleForTesting InvokeApi? mockInvokeApi,
  })  : _rateLimiter = RateLimiter(maxRequestsPerSecond: maxRequestsPerSecond),
        _mockInvokeAPI = mockInvokeApi;

  final RateLimiter _rateLimiter;
  final RateLimitStatPrinter _stats = RateLimitStatPrinter();
  final InvokeApi? _mockInvokeAPI;

  /// Called by other code for printing.
  int get maxRequestsPerSecond => _rateLimiter.maxRequestsPerSecond;

  // static DateTime? _parseResetTime(Response response) {
  //   final resetString = response.headers['x-ratelimit-reset'];
  //   if (resetString == null) {
  //     return null;
  //   }
  //   return DateTime.parse(resetString);
  // }

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

  /// Just makes some code cleaner below.
  int get _backoffSeconds => _rateLimiter.backoffSeconds;

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
          'Unexpected ${response.statusCode} response: ${response.body}, '
          'retrying after $_backoffSeconds seconds',
        );
      } catch (e) {
        // Network errors are transient and we retry.
        logger.warn(
          'Unexpected $e, retrying after $_backoffSeconds seconds',
        );
      }
      // Override the wait time for testing.
      _rateLimiter.requestCameBackRateLimited(
        overrideWaitTime: overrideWaitTime,
      );
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

    final doInvokeAPI = _mockInvokeAPI ?? super.invokeAPI;

    final response = await handleUnexpectedRateLimit(
      () async {
        _stats.printIfNeeded();
        // Wait for our turn (even when retrying)
        await _rateLimiter.waitForRateLimit();
        // Could include retry count here.
        logger.detail('$path$queryString');
        // Actually do the request.
        final response = await doInvokeAPI(
          path,
          method,
          queryParams,
          body,
          headerParams,
          formParams,
          contentType,
        );
        _stats.record(response);
        return response;
      },
    );
    // We sucessfully got a request off, we can reset our backoff.
    _rateLimiter.requestCompleted();
    return response;
  }
}
