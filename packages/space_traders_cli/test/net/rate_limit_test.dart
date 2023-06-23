import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/rate_limit.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('handleUnexpectedRateLimit', () async {
    var callCount = 0;
    Future<Response> sendRequest() async {
      callCount++;
      if (callCount == 1) {
        throw ApiException(429, 'rate limited');
      }
      return Response('ok', 200);
    }

    final logger = _MockLogger();
    final response = await runWithLogger(
      logger,
      () => RateLimitedApiClient.handleUnexpectedRateLimit(
        sendRequest,
        waitTimeSeconds: 0,
      ),
    );
    verify(
      () => logger.warn(
        'Unexpected rate limit response, waiting 0 seconds and retrying',
      ),
    ).called(1);
    expect(response.statusCode, 200);
    expect(callCount, 2);
  });
}
