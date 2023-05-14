import 'dart:convert';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

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

bool shouldSellItem(String tradeSymbol) {
  // Could choose not to sell contract items if we have a contract that needs them.
  // Current excluding antimatter because it's unclear how rare it is?
  Set<String> excludedItems = {"ANTIMATTER"};
  return !excludedItems.contains(tradeSymbol);
}

Future<void> sellCargo(Api api, Ship ship) async {
  if (ship.cargo.inventory.isEmpty) {
    logger.info("${ship.symbol}: No cargo to sell");
    return;
  }
  // logCargo(ship);
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
    if (!shouldSellItem(item.symbol)) {
      continue;
    }
    final sellRequest = SellCargoRequest(
      symbol: item.symbol,
      units: item.units,
    );
    final sellResponse =
        await api.fleet.sellCargo(ship.symbol, sellCargoRequest: sellRequest);
    final transaction = sellResponse!.data.transaction;
    logger.info(
        "${ship.symbol}: Sold ${transaction.units} ${transaction.tradeSymbol} for ${transaction.totalPrice}c");
  }
}

/// One loop of the mining logic
Future<DateTime?> advanceMiner(
    Api api, Ship ship, List<Waypoint> systemWaypoints) async {
  if (ship.isInTransit) {
    // Do nothing for now.
    return ship.nav.route.arrival;
  }
  if (ship.isOrbiting) {
    logger.info(
        "${ship.symbol}: Docking ${ship.symbol} at ${ship.nav.waypointSymbol}");
    await api.fleet.dockShip(ship.symbol);
    return null;
  }
  if (ship.isDocked) {
    if (ship.fuel.current < ship.fuel.capacity) {
      logger.info("${ship.symbol}: Refueling");
      await api.fleet.refuelShip(ship.symbol);
      return null;
    }
    final currentWaypoint =
        lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    if (currentWaypoint.isAsteroidField) {
      // If we still have space, mine.
      if (ship.spaceAvailable > 0) {
        logger.info(
            "${ship.symbol}: Mining (cargo: ${ship.cargo.units}/${ship.cargo.capacity})");
        await api.fleet.extractResources(ship.symbol);
        // We don't return the expiration time because we don't want to force
        // a wait, in case it might plan to do something else next.
        // Instead we'll let it try again and catch the cooldown
        // exception if it's still cooling down.
        return null;
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
        logger.info("${ship.symbol}: Cargo full, selling");
        await sellCargo(api, ship);
      }
    } else {
      // Fulfill contract if we have one.
      // Otherwise, sell ore.
      await sellCargo(api, ship);
      // Otherwise return to asteroid.
      final asteroidField =
          systemWaypoints.firstWhere((w) => w.isAsteroidField);
      logger.info("${ship.symbol}: Navigating to ${asteroidField.symbol}");
      final result = await navigateTo(api, ship, asteroidField);
      final flightTime = result.nav.route.arrival.difference(DateTime.now());
      logger.info("${ship.symbol}: Expected in ${flightTime.inSeconds}s.");
    }
  }
  return null;
}

bool shouldUseForMining(Ship ship) {
  // Could check if it has a mining laser.
  // return ship.isExcavator;
  return true; // All ships for now.
}

/// One loop of the logic.
Stream<DateTime> logicLoop(Api api) async* {
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  logger.info("Credits: ${agent.credits}");
  final hq = parseWaypointString(agentResult.data.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);
  final myShips = await allMyShips(api).toList();
  if (shouldPurchaseMiner(agent, myShips)) {
    logger.info("Purchasing mining drone.");
    final shipyardWaypoint = systemWaypoints.firstWhere((w) => w.hasShipyard);
    final purchaseResponse =
        await purchaseShip(api, ShipType.MINING_DRONE, shipyardWaypoint.symbol);
    logger.info("Purchased ${purchaseResponse.ship.symbol}");
    return; // Fetch ship lists again.
  }

  // printShips(myShips, systemWaypoints);
  // loop over all mining ships and advance them.
  for (var ship in myShips) {
    if (shouldUseForMining(ship)) {
      try {
        var maybeWaitUntil = await advanceMiner(api, ship, systemWaypoints);
        if (maybeWaitUntil != null) {
          yield maybeWaitUntil;
        }
      } on ApiException catch (e) {
        if (e.code == 409) {
          // What we tried to do was still on cooldown.
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

/// Returns true if we should purchase a new ship.
/// Currently just returns true if we have no mining ships.
bool shouldPurchaseMiner(Agent myAgent, List<Ship> ships) {
  // If we have no mining ships, purchase one.
  if (ships.every((s) => !s.isExcavator)) {
    return true;
  }
  // This should be dynamic based on market prices?
  // Risk is that it will try to purchase and fail (causing an exception).
  return myAgent.credits > 140000;
}

/// Run the logic loop forever.
/// Currently just sends ships to mine and sell ore.
void logic(Api api) async {
  while (true) {
    final nextEventTimes = await logicLoop(api).toList();
    if (nextEventTimes.isNotEmpty) {
      final earliestWaitUntil =
          nextEventTimes.reduce((a, b) => a.isBefore(b) ? a : b);
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.now());
      logger.info("Waiting ${waitDuration.inSeconds}s");
      await Future.delayed(earliestWaitUntil.difference(DateTime.now()));
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
