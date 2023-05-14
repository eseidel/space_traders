import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';

// This probably doesn't belong here.
Waypoint lookupWaypoint(String waypointSymbol, List<Waypoint> systemWaypoints) {
  return systemWaypoints.firstWhere((w) => w.symbol == waypointSymbol);
}

void printWaypoints(List<Waypoint> waypoints) async {
  for (var waypoint in waypoints) {
    print(
        "${waypoint.symbol} - ${waypoint.type} - ${waypoint.traits.map((w) => w.name).join(', ')}");
  }
}

void printShips(List<Ship> ships, List<Waypoint> systemWaypoints) {
  for (var ship in ships) {
    final waypoint = lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    var string =
        "${ship.symbol} - ${ship.navStatusString} ${waypoint.type} ${ship.registration.role}";
    if (ship.crew.morale != 100) {
      string += " (morale: ${ship.crew.morale})";
    }
    if (ship.averageCondition != 100) {
      string += " (condition: ${ship.averageCondition})";
    }
    print(string);
  }
}
