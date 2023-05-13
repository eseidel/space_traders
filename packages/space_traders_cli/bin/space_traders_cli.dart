import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
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

void printWaypointsInSystem(Api api, String system) async {
  final waypointsResponse = await api.systems.getSystemWaypoints(system);
  for (var waypoint in waypointsResponse!.data) {
    print(
        "${waypoint.symbol} - ${waypoint.traits.map((w) => w.name).join(', ')}");
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

void quickStart(String authToken) async {
  final auth = HttpBearerAuth();
  auth.accessToken = authToken;

  final api = Api(ApiClient(authentication: auth));
  final agentResult = await api.agents.getMyAgent();

  final shipsResponse = await api.fleet.getMyShips();
  // TODO: This check is wrong because you start with a ship.
  // We should check if you already have a mining drone.
  if (shipsResponse!.data.isEmpty) {
    print("No ships, purchasing one");
    final hq = parseWaypointString(agentResult!.data.headquarters);
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
      print("${ship.symbol} - ${ship.nav.status} ${ship.nav.waypointSymbol}");
    }
  }
}

void main(List<String> arguments) async {
  var logger = Logger();
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
