import 'dart:convert';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/queries.dart';

/// Used to accept the first contract in the list of contracts.
/// Which is the case when just starting the game.
Future<void> acceptFirstContract(Api api) async {
  final contracts = await api.contracts.getContracts();
  logger.info(contracts.toString());

  final firstContract = contracts!.data.first;
  logger.info(firstContract.toString());

  final response = await api.contracts.acceptContract(firstContract.id);
  logger.info(response.toString());
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

bool _shouldSellItem(String tradeSymbol) {
  // Could choose not to sell contract items if we have a contract that needs
  // them. Current excluding antimatter because it's unclear how rare it is?
  final excludedItems = <String>{'ANTIMATTER'};
  return !excludedItems.contains(tradeSymbol);
}

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// Logs each transaction or "No cargo to sell" if there is no cargo.
Future<void> sellCargoAndLog(
  Api api,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async {
  if (ship.cargo.inventory.isEmpty) {
    logger.info('${ship.symbol}: No cargo to sell');
    return;
  }
  await for (final response in sellCargo(api, ship, where: where)) {
    final transaction = response.transaction;
    logger.info(
      '${ship.symbol}: Sold ${transaction.units} ${transaction.tradeSymbol} '
      'for ${transaction.totalPrice}c',
    );
  }
}

/// One loop of the mining logic
Future<DateTime?> advanceMiner(
  Api api,
  Ship ship,
  List<Waypoint> systemWaypoints,
) async {
  if (ship.isInTransit) {
    // Do nothing for now.
    return ship.nav.route.arrival;
  }
  if (ship.isOrbiting) {
    logger.info(
      '${ship.symbol}: Docking ${ship.symbol} at ${ship.nav.waypointSymbol}',
    );
    await api.fleet.dockShip(ship.symbol);
    return null;
  }
  if (ship.isDocked) {
    if (ship.fuel.current < ship.fuel.capacity) {
      logger.info('${ship.symbol}: Refueling');
      await api.fleet.refuelShip(ship.symbol);
      return null;
    }
    final currentWaypoint =
        lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    if (currentWaypoint.isAsteroidField) {
      // If we still have space, mine.
      if (ship.spaceAvailable > 0) {
        // Check cooldown and return if cooling down?
        // logger.info(
        //     "${ship.symbol}: Mining (cargo: ${ship.cargo.units}/${ship.cargo.capacity})");
        final response = await api.fleet.extractResources(ship.symbol);
        final yield_ = response!.data.extraction.yield_;
        final cargo = response.data.cargo;
        logger.info('${ship.symbol}: Mined ${yield_.units} ${yield_.symbol} '
            '(cargo: ${cargo.units}/${cargo.capacity})');
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
        //   final contractNeedingItem =
        //       contractsResponse!.data.firstWhereOrNull(
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
        await sellCargoAndLog(api, ship, where: _shouldSellItem);
      }
    } else {
      // Fulfill contract if we have one.
      // Otherwise, sell ore.
      await sellCargoAndLog(api, ship, where: _shouldSellItem);
      // Otherwise return to asteroid.
      final asteroidField =
          systemWaypoints.firstWhere((w) => w.isAsteroidField);
      logger.info('${ship.symbol}: Navigating to ${asteroidField.symbol}');
      final result = await navigateTo(api, ship, asteroidField);
      final flightTime = result.nav.route.arrival.difference(DateTime.now());
      logger.info('${ship.symbol}: Expected in ${flightTime.inSeconds}s.');
    }
  }
  return null;
}

bool _shouldUseForMining(Ship ship) {
  // Could check if it has a mining laser.
  // return ship.isExcavator;
  return true; // All ships for now.
}

/// One loop of the logic.
Stream<DateTime> logicLoop(Api api) async* {
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  logger.info('Credits: ${agent.credits}');
  final hq = parseWaypointString(agentResult.data.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);
  final myShips = await allMyShips(api).toList();
  if (shouldPurchaseMiner(agent, myShips)) {
    logger.info('Purchasing mining drone.');
    final shipyardWaypoint = systemWaypoints.firstWhere((w) => w.hasShipyard);
    final purchaseResponse =
        await purchaseShip(api, ShipType.MINING_DRONE, shipyardWaypoint.symbol);
    logger.info('Purchased ${purchaseResponse.ship.symbol}');
    return; // Fetch ship lists again.
  }

  // printShips(myShips, systemWaypoints);
  // loop over all mining ships and advance them.
  for (final ship in myShips) {
    if (_shouldUseForMining(ship)) {
      try {
        final maybeWaitUntil = await advanceMiner(api, ship, systemWaypoints);
        if (maybeWaitUntil != null) {
          yield maybeWaitUntil;
        }
      } on ApiException catch (e) {
        if (e.code == 409) {
          // What we tried to do was still on cooldown.
          final jsonString = e.message;
          if (jsonString != null) {
            final exceptionJson =
                jsonDecode(jsonString) as Map<String, dynamic>;
            final error = exceptionJson['error'] as Map<String, dynamic>?;
            final errorData = error?['data'] as Map<String, dynamic>?;
            final cooldown = errorData?['cooldown'];
            final expiration = mapDateTime(cooldown, 'expiration');
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
Future<void> logic(Api api) async {
  while (true) {
    final nextEventTimes = await logicLoop(api).toList();
    if (nextEventTimes.isNotEmpty) {
      final earliestWaitUntil =
          nextEventTimes.reduce((a, b) => a.isBefore(b) ? a : b);
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.now());
      logger.info('Waiting ${waitDuration.inSeconds}s');
      await Future<void>.delayed(earliestWaitUntil.difference(DateTime.now()));
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
