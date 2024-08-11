import 'package:cli/net/auth.dart';
import 'package:cli/net/counts.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDatabase extends Mock implements Database {}

void main() {
  test('loadAuthToken', () async {
    final db = _MockDatabase();
    when(db.getAuthToken).thenAnswer((_) async => null);
    expect(() => defaultApi(db), throwsException);
    when(db.getAuthToken).thenAnswer((_) async => 'token');
    final api = await defaultApi(db);
    expect(api.apiClient, isA<CountingApiClient>());
  });
}
