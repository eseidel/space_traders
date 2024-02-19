import 'package:cli/cli.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('runOffline', () {
    final logger = _MockLogger();
    runOffline(
      ['-v'],
      (fs, db, results) async {
        expect(results['verbose'], true);
        expect(results['help'], false);
      },
      overrideLogger: logger,
    );
    verify(() => logger.level = Level.verbose).called(1);
  });

  test('shipTypeFromArg, argFromShipType', () {
    expect(shipTypeFromArg('COMMAND_FRIGATE'), ShipType.COMMAND_FRIGATE);
    expect(argFromShipType(ShipType.COMMAND_FRIGATE), 'COMMAND_FRIGATE');
  });
}
