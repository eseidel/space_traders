import 'package:cli_client/cli_args.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('shipTypeFromArg, argFromShipType', () {
    expect(shipTypeFromArg('COMMAND_FRIGATE'), ShipType.COMMAND_FRIGATE);
    expect(argFromShipType(ShipType.COMMAND_FRIGATE), 'COMMAND_FRIGATE');
  });
}
