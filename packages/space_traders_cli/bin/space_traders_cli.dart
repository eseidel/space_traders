import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/space_traders_cli.dart';

void printHq(Api api) async {
  final agentResult = await api.agents.getMyAgent();
  final hq = parseWaypointString(agentResult!.data.headquarters);
  final waypoint = await api.systems.getWaypoint(hq.system, hq.waypoint);
  print(waypoint);
}

void acceptFirstContract(Api api) async {
  final contracts = await api.contracts.getContracts();
  print(contracts);

  final firstContract = contracts!.data.first;
  print(firstContract);

  final response = await api.contracts.acceptContract(firstContract.id);
  print(response);
}

void printWaypoints(List<Waypoint> waypoints) async {
  for (var waypoint in waypoints) {
    print(
        "${waypoint.symbol} - ${waypoint.type} - ${waypoint.traits.map((w) => w.name).join(', ')}");
  }
}

void printAvailableShipsAt(Api api, String waypoint) async {
  final parsed = parseWaypointString(waypoint);
  final shipyardResponse =
      await api.systems.getShipyard(parsed.system, parsed.waypoint);
  for (var shipType in shipyardResponse!.data.shipTypes) {
    print("${shipType.type}");
  }
  final ships = shipyardResponse.data.ships;
  for (var ship in ships) {
    print("${ship.type} - ${ship.purchasePrice}");
  }
}

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

void quickStart(String authToken) async {
  final auth = HttpBearerAuth();
  auth.accessToken = authToken;

  final api = Api(ApiClient(authentication: auth));
  final agentResult = await api.agents.getMyAgent();
  final hq = parseWaypointString(agentResult!.data.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);
  final shipsResponse = await api.fleet.getMyShips();

  // Could also filter out the command ship.
  final excavator = shipsResponse!.data
      .firstWhereOrNull((s) => s.registration.role == ShipRole.EXCAVATOR);
  if (excavator == null) {
    print("No mining ships, purchasing one");
    final shipyardWaypoint = await findShipyard(api, hq.system);
    // printWaypointsInSystem(api, hq.system);
    // printAvailableShipsAt(api, shipyardWaypoint!);
    PurchaseShipRequest purchaseShipRequest = PurchaseShipRequest(
      waypointSymbol: shipyardWaypoint!,
      shipType: ShipType.MINING_DRONE,
    );
    final purchaseResponse =
        await api.fleet.purchaseShip(purchaseShipRequest: purchaseShipRequest);
    print(purchaseResponse);
  } else {
    print("Have ships:");
    for (var ship in shipsResponse.data) {
      print(
          "${ship.symbol} - ${ship.nav.status} ${ship.nav.waypointSymbol} ${ship.registration.role}");
      // prettyPrintJson(ship.toJson());
    }
    printWaypoints(systemWaypoints);

    final astroidField = systemWaypoints
        .firstWhere((w) => w.type == WaypointType.ASTEROID_FIELD);
    print(astroidField);

    api.fleet.navigateShip(excavator.symbol,
        navigateShipRequest:
            NavigateShipRequest(waypointSymbol: astroidField.symbol));
  }
}

void main(List<String> arguments) async {
  logger.info("Welcome to Space Traders! 🚀");
  // Use package:file to make things mockable.
  var fs = const LocalFileSystem();
  // If we have an auth token file, use that.
  while (true) {
    try {
      final token = await fs.file('auth_token.txt').readAsString();
      quickStart(token);
      break;
    } catch (e) {
      logger.info("No auth token found.");
      // Otherwise, register a new user.
      final handle = logger.prompt("What is your call sign?");
      final token = await register(handle);
      await fs.file('auth_token.txt').writeAsString(token);
    }
  }
}
