import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/logger.dart';

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

void printShips(List<Ship> ships, List<Waypoint> systemWaypoints) {
  for (var ship in ships) {
    final waypoint = lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    print(
        "${ship.symbol} - ${ship.navStatusString} ${waypoint.type} ${ship.registration.role}");
  }
}

Future<PurchaseShip201ResponseData> purchaseMiningShip(
    Api api, List<Waypoint> systemWaypoints) async {
  final shipyardWaypoint = systemWaypoints.firstWhere((w) => w.hasShipyard);
  PurchaseShipRequest purchaseShipRequest = PurchaseShipRequest(
    waypointSymbol: shipyardWaypoint.symbol,
    shipType: ShipType.MINING_DRONE,
  );
  final purchaseResponse =
      await api.fleet.purchaseShip(purchaseShipRequest: purchaseShipRequest);
  return purchaseResponse!.data;
}

Waypoint lookupWaypoint(String waypointSymbol, List<Waypoint> systemWaypoints) {
  return systemWaypoints.firstWhere((w) => w.symbol == waypointSymbol);
}

extension on Waypoint {
  bool hasTrait(WaypointTraitSymbolEnum trait) {
    return traits.any((t) => t.symbol == trait);
  }

  bool isType(WaypointType type) {
    return this.type == type;
  }

  bool get isAsteroidField => isType(WaypointType.ASTEROID_FIELD);
  bool get hasShipyard => hasTrait(WaypointTraitSymbolEnum.SHIPYARD);
  bool get hasMarketplace => hasTrait(WaypointTraitSymbolEnum.MARKETPLACE);
}

extension on Ship {
  int get spaceAvailable => cargo.capacity - cargo.units;

  bool get isExcavator => registration.role == ShipRole.EXCAVATOR;

  bool get isInTransit => nav.status == ShipNavStatus.IN_TRANSIT;
  bool get isDocked => nav.status == ShipNavStatus.DOCKED;
  bool get isOrbiting => nav.status == ShipNavStatus.IN_ORBIT;

  String get navStatusString {
    switch (nav.status) {
      case ShipNavStatus.DOCKED:
        return "Docked at ${nav.waypointSymbol}";
      case ShipNavStatus.IN_ORBIT:
        return "Orbiting ${nav.waypointSymbol}";
      case ShipNavStatus.IN_TRANSIT:
        return "In transit to ${nav.waypointSymbol}";
      default:
        return "Unknown";
    }
  }
}

void logCargo(Ship ship) {
  logger.info("Cargo:");
  for (var item in ship.cargo.inventory) {
    logger.info("  ${item.units.toString().padLeft(3)} ${item.name}");
  }
}

Future<DateTime?> advanceMiner(
    Api api, Ship ship, List<Waypoint> systemWaypoints) async {
  // Cases:
  // In transit:
  //  Do nothing for now (assume on right course).
  // Orbiting:
  //  Dock.
  // At asteroid:
  // Refuel.
  // Mine (ideally what's on our contract, otherwise whatever.)
  // If full, return to HQ.
  // At HQ:
  // Fulfill contract if we have one.
  // Otherwise, sell ore.
  // Refuel.
  // If empty, return to asteroid.

  if (ship.isInTransit) {
    // Do nothing for now.
    return ship.nav.route.arrival;
  }
  if (ship.isOrbiting) {
    print("Docking ${ship.symbol} at ${ship.nav.waypointSymbol}");
    await api.fleet.dockShip(ship.symbol);
    return null;
  }
  if (ship.isDocked) {
    if (ship.fuel.current < ship.fuel.capacity) {
      print("Refueling");
      await api.fleet.refuelShip(ship.symbol);
      return null;
    }
    final waypoint = lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    if (waypoint.isAsteroidField) {
      // If we still have space, mine.
      if (ship.spaceAvailable > 0) {
        print("Mining (space available: ${ship.spaceAvailable})");
        final extractResponse = await api.fleet.extractResources(ship.symbol);
        return extractResponse!.data.cooldown.expiration;
      } else {
        // Otherwise, sell cargo.
        print("Cargo full, selling");
        logCargo(ship);
        // final contractsResponse = await api.contracts.getContracts();
        // print("Contracts: ${contractsResponse!.data}");
        // final marketplaces =
        //     systemWaypoints.where((w) => w.hasMarketplace).toList();
        // printWaypoints(marketplaces);

        // final marketResponse =
        //     await api.systems.getMarket(waypoint.systemSymbol, waypoint.symbol);
        // final market = marketResponse!.data;
        // prettyPrintJson(market.toJson());

        // This should not sell anything we have a contract for.
        // We should travel first to the marketplace that has the best price for
        // the ore we have a contract for.
        for (final item in ship.cargo.inventory) {
          final sellRequest = SellCargoRequest(
            symbol: item.symbol,
            units: item.units,
          );
          final sellResponse = await api.fleet
              .sellCargo(ship.symbol, sellCargoRequest: sellRequest);
          final transaction = sellResponse!.data.transaction;
          print(
              "Sold ${transaction.units} ${transaction.tradeSymbol} for ${transaction.totalPrice}");
        }
      }
    } else {
      throw "not implemented";
      // Fulfill contract if we have one.
      // Otherwise, sell ore.
      // Otherwise return to asteroid.
    }
  }
  return null;
}

Stream<DateTime> logicLoop(Api api) async* {
  final agentResult = await api.agents.getMyAgent();
  logger.info("Credits: ${agentResult!.data.credits}");
  final hq = parseWaypointString(agentResult.data.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);
  final myShips = await allMyShips(api).toList();
  if (shouldPurchaseShip(myShips)) {
    print("No mining ships, purchasing one");
    final purchaseResponse = await purchaseMiningShip(api, systemWaypoints);
    print("Purchased ${purchaseResponse.ship.symbol}");
    return; // Fetch ship lists again.
  }

  printShips(myShips, systemWaypoints);
  // loop over all mining ships and advance them.
  for (var ship in myShips) {
    if (ship.isExcavator) {
      var maybeWaitUntil = await advanceMiner(api, ship, systemWaypoints);
      if (maybeWaitUntil != null) {
        yield maybeWaitUntil;
      }
    }
  }
}

bool shouldPurchaseShip(List<Ship> ships) {
  // Can have fancier logic here later.
  return ships.every((s) => !s.isExcavator);
}

void logic(Api api) async {
  while (true) {
    final nextEventTimes = await logicLoop(api).toList();
    if (nextEventTimes.isNotEmpty) {
      final earliestWaitUntil =
          nextEventTimes.reduce((a, b) => a.isBefore(b) ? a : b);
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.now());
      logger.info("Waiting $waitDuration");
      await Future.delayed(earliestWaitUntil.difference(DateTime.now()));
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}

void main(List<String> arguments) async {
  logger.info("Welcome to Space Traders! 🚀");
  // Use package:file to make things mockable.
  var fs = const LocalFileSystem();
  // If we have an auth token file, use that.
  while (true) {
    try {
      final token = (await fs.file('auth_token.txt').readAsString()).trim();
      final auth = HttpBearerAuth()..accessToken = token;
      final api = Api(ApiClient(authentication: auth));
      logic(api);
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
