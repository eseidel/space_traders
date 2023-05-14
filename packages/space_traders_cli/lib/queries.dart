import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';

// Need to make these generic for all paginated apis.

/// Fetches all waypoints in a system.  Handles pagination from the server.
Future<List<Waypoint>> waypointsInSystem(Api api, String system) async {
  final waypoints = <Waypoint>[];
  var page = 1;
  var remaining = 0;
  do {
    final waypointsResponse =
        await api.systems.getSystemWaypoints(system, page: page);
    waypoints.addAll(waypointsResponse!.data);
    remaining = waypointsResponse.meta.total - waypoints.length;
    page++;
  } while (remaining > 0);
  return waypoints;
}

/// Fetches all of the user's ships.  Handles pagination from the server.
Stream<Ship> allMyShips(Api api) async* {
  var page = 1;
  var count = 0;
  var remaining = 0;
  do {
    final shipsResponse = await api.fleet.getMyShips(page: page);
    count += shipsResponse!.data.length;
    remaining = shipsResponse.meta.total - count;
    for (final ship in shipsResponse.data) {
      yield ship;
    }
    page++;
  } while (remaining > 0);
}
