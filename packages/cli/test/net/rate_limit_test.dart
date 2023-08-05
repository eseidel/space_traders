import 'package:cli/logger.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('handleUnexpectedRateLimit', () async {
    var callCount = 0;
    Future<Response> sendRequest() async {
      callCount++;
      if (callCount == 1) {
        return Response('rate limited', 429);
      }
      return Response('ok', 200);
    }

    final logger = _MockLogger();
    final client = RateLimitedApiClient();
    final response = await runWithLogger(
      logger,
      () => client.handleUnexpectedRateLimit(
        sendRequest,
        overrideWaitTime: Duration.zero,
      ),
    );
    verify(
      () => logger.warn(
        'Unexpected 429 response: rate limited, retrying after 1 seconds',
      ),
    ).called(1);
    expect(response.statusCode, 200);
    expect(callCount, 2);
  });

  test('RateLimiter first request immediate', () async {
    FakeAsync().run((async) {
      final rateLimiter = RateLimiter(maxRequestsPerSecond: 1);
      final timings = <int>[];
      // Skip 10 seconds so that the "last request time" is in the past.
      async.elapse(const Duration(seconds: 10));
      final startTime = clock.now();
      for (var i = 0; i < 10; i++) {
        rateLimiter.waitForRateLimit().then((_) {
          final delay = clock.now().difference(startTime);
          timings.add(delay.inMilliseconds);
          rateLimiter.requestCompleted();
        });
      }
      async.elapse(const Duration(seconds: 10));
      expect(
        timings,
        // First request is immediate.
        [0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000],
      );
    });
  });

  test('RateLimiter requests are immediate after delays', () async {
    FakeAsync().run((async) {
      final rateLimiter = RateLimiter(maxRequestsPerSecond: 1);
      final timings = <int>[];
      // Skip 10 seconds so that the "last request time" is in the past.
      async.elapse(const Duration(seconds: 10));
      final startTime = clock.now();
      rateLimiter.waitForRateLimit().then((_) {
        final delay = clock.now().difference(startTime);
        timings.add(delay.inMilliseconds);
        rateLimiter.requestCompleted();
      });
      async.elapse(const Duration(seconds: 5));
      rateLimiter.waitForRateLimit().then((_) {
        final delay = clock.now().difference(startTime);
        timings.add(delay.inMilliseconds);
        rateLimiter.requestCompleted();
      });
      // Let the last request complete.
      async.elapse(const Duration(seconds: 5));
      expect(
        timings,
        // First request is immediate, second request is delayed by 5 seconds
        // so is immediate after that.
        [0, 5000],
      );
    });
  });

  test('RateLimiter long requests delay later requests', () async {
    final logger = _MockLogger();
    // rateLimiter logs a warning when a request is delayed.
    runWithLogger(logger, () {
      FakeAsync().run((async) {
        final rateLimiter = RateLimiter(maxRequestsPerSecond: 2);
        final timings = <int>[];
        // Skip 10 seconds so that the "last request time" is in the past.
        async.elapse(const Duration(seconds: 10));
        final startTime = clock.now();
        rateLimiter.waitForRateLimit().then((_) {
          final delay = clock.now().difference(startTime);
          timings.add(delay.inMilliseconds);
          // Delay completion of the first request by 2 seconds.
          Future<void>.delayed(
            const Duration(seconds: 2),
            rateLimiter.requestCompleted,
          );
        });
        for (var i = 0; i < 2; i++) {
          rateLimiter.waitForRateLimit().then((_) {
            final delay = clock.now().difference(startTime);
            timings.add(delay.inMilliseconds);
            rateLimiter.requestCompleted();
          });
        }
        async.elapse(const Duration(seconds: 10));
        expect(
          timings,
          // First request is started immediately, but takes 2 seconds so delays
          // the start of the second request.  The second request only starts
          // the normal time delay *after* the first request completes.
          [0, 2500, 3000],
        );
      });
    });
  });

  test('RateLimiter backoff', () async {
    FakeAsync().run((async) {
      final rateLimiter = RateLimiter(maxRequestsPerSecond: 2);
      final timings = <int>[];
      // Skip 10 seconds so that the "last request time" is in the past.
      async.elapse(const Duration(seconds: 10));
      final startTime = clock.now();
      for (var i = 0; i < 10; i++) {
        rateLimiter.waitForRateLimit().then((_) {
          final delay = clock.now().difference(startTime);
          timings.add(delay.inMilliseconds);
          if ([0, 2, 3, 5, 6, 7].contains(i)) {
            rateLimiter.requestCameBackRateLimited();
          } else {
            rateLimiter.requestCompleted();
          }
        });
      }
      async.elapse(const Duration(seconds: 20));
      expect(
        timings,
        [
          0, // 0 is immediate, rate limit response.
          1000, // 1 is delayed by 1s (default backoff), normal response.
          1500, // 2 is after normal delay, rate limit response.
          2500, // 3 is delayed by 1s (default backoff), rate limit response.
          4500, // 4 is delayed by 2s (2x default backoff), normal response.
          5000, // 5 is after normal delay, rate limit response.
          6000, // 6 is delayed by 1s (default backoff), rate limit response.
          8000, // 7 is delayed by 2s (2x default backoff), rate limit response.
          12000, // 8 is delayed by 4s (4x default backoff), normal response.
          12500, // 9 is after normal delay, normal response.
        ],
      );
    });
  });
}
