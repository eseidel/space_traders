import 'package:types/types.dart';

/// Get a ship type from a command line argument.
ShipType shipTypeFromArg(String arg) {
  final upper = arg.toUpperCase();
  final name = upper.startsWith('SHIP_') ? upper : 'SHIP_$upper';
  return ShipType.values.firstWhere((e) => e.value == name);
}

/// Get a command line argument from a ship type.
String argFromShipType(ShipType shipType) {
  return shipType.value.substring('SHIP_'.length);
}
