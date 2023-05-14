import 'dart:convert';

import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';

/// Used to accept the first contract in the list of contracts.
/// Which is the case when just starting the game.
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

void logCargo(Ship ship) {
  logger.info("Cargo:");
  for (var item in ship.cargo.inventory) {
    logger.info("  ${item.units.toString().padLeft(3)} ${item.name}");
  }
}

// Iterable<String> tradeSymbolsFromContracts(List<Contract> contracts) sync* {
//   for (final contract in contracts) {
//     for (final item in contract.terms.deliver) {
//       yield item.tradeSymbol;
//     }
//   }
// }

// Contract? contractNeedingItem(
//     List<Contract> contracts, String tradeSymbol) {
//   for (final contract in contracts) {
//     for (final item in contract.terms.deliver) {
//       if (item.tradeSymbol == tradeSymbol) {
//         return contract;
//       }
//     }
//   }
//   return null;
// }

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
  // If full:
  //  If have goods related to contract, go to contract waypoint.
  //  Otherwise, sell goods.
  // Not at an asteroid:
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
        // TODO: It is possible to navigate while mining is on cooldown.
        return extractResponse!.data.cooldown.expiration;
      } else {
        // Otherwise check to see if we have cargo that is relevant for our
        // contract.
        // final contractsResponse = await api.contracts.getContracts();

        // final itemsInCargo = ship.cargo.inventory.map((i) => i.symbol);

        // for (var item in itemsInCargo) {
        //   final contractNeedingItem = contractsResponse!.data.firstWhereOrNull(
        //       (c) => c.needsItem(item) && c.issuer != ship.owner);
        //   if (contractNeedingItem != null) {
        //     print("Contract needs $item, returning to HQ");
        //     final waypoint =
        //         lookupWaypoint(contractNeedingItem.issuer, systemWaypoints);
        //     await api.fleet.setShipNav(
        //         ship.symbol, waypoint.systemSymbol, waypoint.symbol);
        //     return null;
        //   }
        // }

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
      try {
        var maybeWaitUntil = await advanceMiner(api, ship, systemWaypoints);
        if (maybeWaitUntil != null) {
          yield maybeWaitUntil;
        }
      } on ApiException catch (e) {
        if (e.code == 409) {
          // Still on cooldown.
          var jsonString = e.message;
          if (jsonString != null) {
            var exceptionJson = jsonDecode(jsonString);
            var cooldown = exceptionJson["error"]?["data"]?["cooldown"];
            var expiration = mapDateTime(cooldown, 'expiration');
            if (expiration != null) {
              yield expiration;
            }
          }
          continue;
        }
        rethrow;
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
  var token = await loadAuthTokenOrRegister(fs);
  var api = apiFromAuthToken(token);
  logic(api);
}
