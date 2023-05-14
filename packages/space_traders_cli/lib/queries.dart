import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';

// Need to make this generic for all paginated apis.
Future<List<Waypoint>> waypointsInSystem(Api api, String system) async {
  List<Waypoint> waypoints = [];
  int page = 1;
  int remaining = 0;
  do {
    final waypointsResponse =
        await api.systems.getSystemWaypoints(system, page: page);
    waypoints.addAll(waypointsResponse!.data);
    remaining = waypointsResponse.meta.total - waypoints.length;
    page++;
  } while (remaining > 0);
  return waypoints;
}

// Need to make this generic for all paginated apis.
Stream<Ship> allMyShips(Api api) async* {
  int page = 1;
  int count = 0;
  int remaining = 0;
  do {
    final shipsResponse = await api.fleet.getMyShips(page: page);
    count += shipsResponse!.data.length;
    remaining = shipsResponse.meta.total - count;
    for (var ship in shipsResponse.data) {
      yield ship;
    }
    page++;
  } while (remaining > 0);
}
