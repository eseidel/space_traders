import 'package:cli/cli.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockDatabase extends Mock implements Database {}

void main() {
  test('runOffline', () {
    final logger = _MockLogger();
    final db = _MockDatabase();
    when(db.close).thenAnswer((_) async {});
    runOffline(
      ['-v'],
      (fs, db, results) async {
        expect(results['verbose'], true);
        expect(results['help'], false);
      },
      overrideLogger: logger,
      overrideDatabase: db,
    );
    verify(() => logger.level = Level.verbose).called(1);
    verify(db.close).called(1);
  });

  test('shipTypeFromArg, argFromShipType', () {
    expect(shipTypeFromArg('COMMAND_FRIGATE'), ShipType.COMMAND_FRIGATE);
    expect(argFromShipType(ShipType.COMMAND_FRIGATE), 'COMMAND_FRIGATE');
  });
}
