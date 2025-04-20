import 'package:cli/cli.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockDatabase extends Mock implements Database {}

void main() {
  test('runOffline', () async {
    final logger = _MockLogger();
    final db = _MockDatabase();
    when(db.close).thenAnswer((_) async {});
    await runOffline(
      ['-v'],
      (fs, db, results) async {
        expect(results['verbose'], true);
        expect(results['help'], false);
      },
      overrideLogger: logger,
      overrideDatabase: db,
      loadConfig: false,
    );
    verify(() => logger.level = Level.verbose).called(1);
    verify(db.close).called(1);
  });
}
