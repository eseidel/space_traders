import 'dart:convert';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';

/// Return a string describing the given [waypoint].
String waypointDescription(Waypoint waypoint) {
  return '${waypoint.symbol} - ${waypoint.type} - '
      "${waypoint.traits.map((w) => w.name).join(', ')}";
}

/// Log a string describing the given [waypoints].
void printWaypoints(List<Waypoint> waypoints) {
  for (final waypoint in waypoints) {
    logger.info(waypointDescription(waypoint));
  }
}

/// Return a string describing the given [ship].
/// systemWaypoints is used to look up the waypoint for the ship's
/// waypointSymbol.
String shipDescription(Ship ship, List<Waypoint> systemWaypoints) {
  final waypoint = lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
  var string =
      '${ship.symbol} - ${ship.navStatusString} ${waypoint.type} ${ship.registration.role} ${ship.cargo.units}/${ship.cargo.capacity}';
  if (ship.crew.morale != 100) {
    string += ' (morale: ${ship.crew.morale})';
  }
  if (ship.averageCondition != 100) {
    string += ' (condition: ${ship.averageCondition})';
  }
  return string;
}

/// Log a string describing the given [ships].
void printShips(List<Ship> ships, List<Waypoint> systemWaypoints) {
  for (final ship in ships) {
    logger.info('  ${shipDescription(ship, systemWaypoints)}');
  }
}

/// Log the provided [json] as pretty-printed JSON (indented).
void prettyPrintJson(Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  final prettyprint = encoder.convert(json);
  logger.info(prettyprint);
}

/// Log the given [ship]'s cargo.
void logCargo(Ship ship) {
  logger.info('Cargo:');
  for (final item in ship.cargo.inventory) {
    logger.info('  ${item.units.toString().padLeft(3)} ${item.name}');
  }
}
