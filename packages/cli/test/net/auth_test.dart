import 'package:cli/net/auth.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('loadAuthToken', () {
    final fs = MemoryFileSystem.test();
    expect(() => loadAuthToken(fs), throwsException);
    expect(() => defaultApi(fs), throwsException);

    fs.file(defaultAuthTokenPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('token\n\n');
    expect(loadAuthToken(fs), 'token');

    final api = defaultApi(fs);
    expect(api.apiClient, isA<RateLimitedApiClient>());
  });
}
