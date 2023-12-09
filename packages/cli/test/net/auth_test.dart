import 'package:cli/net/auth.dart';
import 'package:cli/net/counts.dart';
import 'package:db/db.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDatabase extends Mock implements Database {}

void main() {
  test('loadAuthToken', () {
    final fs = MemoryFileSystem.test();
    final db = _MockDatabase();
    expect(() => loadAuthToken(fs), throwsException);
    expect(() => defaultApi(fs, db), throwsException);

    fs.file(defaultAuthTokenPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('token\n\n');
    expect(loadAuthToken(fs), 'token');

    final api = defaultApi(fs, db);
    expect(api.apiClient, isA<CountingApiClient>());
  });
}
