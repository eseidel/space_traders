import 'package:cli/net/auth.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('loadAuthToken', () {
    final fs = MemoryFileSystem.test();
    expect(() => loadAuthToken(fs), throwsException);
    expect(() => defaultApi(fs, ClientType.localLimits), throwsException);

    fs.file(defaultAuthTokenPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('token\n\n');
    expect(loadAuthToken(fs), 'token');

    final api = defaultApi(fs, ClientType.localLimits);
    expect(api.apiClient, isA<RateLimitedApiClient>());
  });
}
