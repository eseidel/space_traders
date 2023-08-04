import 'package:cli/logger.dart';
import 'package:cli/net/rate_limit.dart';
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

  test('RateLimiter', () async {
    // final rateLimiter = RateLimiter();

    // To test:
    // - First request scheduled should be immediate.
    // - Second request should be set to wait.
    // - If a request takes a long time, a second request will not go off
    //   while it's still in progress.
    // - Rate limit responses should retry (above)
    // - If time passes between requests, the next request should be immediate.
  });
}
