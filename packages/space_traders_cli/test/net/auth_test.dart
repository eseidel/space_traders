import 'package:cli/net/auth.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('loadAuthToken', () {
    final fs = MemoryFileSystem.test();
    expect(() => loadAuthToken(fs), throwsException);
    fs.file('auth_token.txt').writeAsStringSync('token\n\n');
    expect(loadAuthToken(fs), 'token');
  });
}
