import 'package:cli/net/auth.dart';
import 'package:cli/net/counts.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDatabase extends Mock implements Database {}

class _MockConfigStore extends Mock implements ConfigStore {}

void main() {
  test('loadAuthToken', () async {
    final db = _MockDatabase();
    final configStore = _MockConfigStore();
    when(() => db.config).thenReturn(configStore);

    when(configStore.getAuthToken).thenAnswer((_) async => null);
    expect(() => defaultApi(db), throwsException);
    when(configStore.getAuthToken).thenAnswer((_) async => 'token');
    final api = await defaultApi(db);
    expect(api.apiClient, isA<CountingApiClient>());
  });
}
