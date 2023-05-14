import 'dart:convert';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';

// This probably doesn't belong here.
Waypoint lookupWaypoint(String waypointSymbol, List<Waypoint> systemWaypoints) {
  return systemWaypoints.firstWhere((w) => w.symbol == waypointSymbol);
}

String waypointDescription(Waypoint waypoint) {
  return "${waypoint.symbol} - ${waypoint.type} - ${waypoint.traits.map((w) => w.name).join(', ')}";
}

void printWaypoints(List<Waypoint> waypoints) async {
  for (var waypoint in waypoints) {
    print(waypointDescription(waypoint));
  }
}

String shipDescription(Ship ship, List<Waypoint> systemWaypoints) {
  final waypoint = lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
  var string =
      "${ship.symbol} - ${ship.navStatusString} ${waypoint.type} ${ship.registration.role} ${ship.cargo.units}/${ship.cargo.capacity}";
  if (ship.crew.morale != 100) {
    string += " (morale: ${ship.crew.morale})";
  }
  if (ship.averageCondition != 100) {
    string += " (condition: ${ship.averageCondition})";
  }
  return string;
}

void printShips(List<Ship> ships, List<Waypoint> systemWaypoints) {
  for (var ship in ships) {
    print("  ${shipDescription(ship, systemWaypoints)}");
  }
}

void prettyPrintJson(Map<String, dynamic> json) {
  JsonEncoder encoder = JsonEncoder.withIndent('  ');
  String prettyprint = encoder.convert(json);
  print(prettyprint);
}

void logCargo(Ship ship) {
  logger.info("Cargo:");
  for (var item in ship.cargo.inventory) {
    logger.info("  ${item.units.toString().padLeft(3)} ${item.name}");
  }
}
