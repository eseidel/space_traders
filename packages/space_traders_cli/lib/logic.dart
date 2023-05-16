import 'package:intl/intl.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
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
    shipInfo(ship, 'No cargo to sell');
    return;
  }
  await for (final response in sellCargo(api, ship, where: where)) {
    final transaction = response.transaction;
    final agent = response.agent;
    final creditsFormat = NumberFormat();
    shipInfo(
      ship,
      '🤝 ${transaction.units.toString().padLeft(2)} '
      // Could use TradeSymbol.values.reduce() to find the longest symbol.
      '${transaction.tradeSymbol.padRight(18)} '
      '${creditsFormat.format(transaction.totalPrice).padLeft(3)}c -> '
      // Always want the 'c' after the credits.
      '🏦 ${creditsFormat.format(agent.credits)}c',
    );
  }
}

/// One loop of the mining logic
Future<DateTime?> advanceMiner(
  Api api,
  DataStore db,
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
      shipInfo(ship, 'Refueling');
      await api.fleet.refuelShip(ship.symbol);
      return null;
    }
    final currentWaypoint =
        lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    if (currentWaypoint.isAsteroidField) {
      // If we still have space, mine.
      // It's not worth potentially waiting a minute just to get one piece of
      // cargo if we're going to sell it right away here.
      // Hence selling when we're down to 5 or fewer spaces left.
      if (ship.spaceAvailable > 5) {
        // If we have surveying capabilities, survey.
        // final latestSurvey = await loadSurvey(db, ship.nav.waypointSymbol);
        // if (latestSurvey == null) {
        //   if (ship.hasSurveyor) {
        //     // Survey
        //     final response = await api.fleet.createSurvey(ship.symbol);
        //     final survey = response!.data;
        //     await saveSurvey(db, survey.surveys);
        //     shipInfo(ship, 'Surveyed ${ship.nav.waypointSymbol}');
        //   }
        // }

        // Check cooldown and return if cooling down?
        // logger.info(
        //     "${ship.symbol}: Mining (cargo: ${ship.cargo.units}/${ship.cargo.capacity})");
        final response = await extractResources(api, ship);
        final yield_ = response.extraction.yield_;
        final cargo = response.cargo;
        // Could use TradeSymbol.values.reduce() to find the longest symbol.
        shipInfo(
            ship,
            // pickaxe requires an extra space on mac?
            '⛏️  ${yield_.units.toString().padLeft(2)} '
            '${yield_.symbol.padRight(18)} '
            // Space after emoji is needed on windows to not bleed together.
            '📦 ${cargo.units.toString().padLeft(2)}/${cargo.capacity}');
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
      shipInfo(ship, 'Navigating to ${asteroidField.symbol}');
      final result = await navigateTo(api, ship, asteroidField);
      final flightTime = result.nav.route.arrival.difference(DateTime.now());
      shipInfo(ship, 'Expected in ${flightTime.inSeconds}s.');
    }
  }
  return null;
}

bool _shouldUseForMining(Ship ship) {
  // Could check if it has a mining laser.
  // return ship.isExcavator;
  return true; // All ships for now.
}

// class _Deal {
//   _Deal({
//     required this.tradeSymbol,
//     required this.destination,
//     required this.sourcePrice,
//     required this.destinationPrice,
//   });

//   final String tradeSymbol;
//   final Waypoint destination;
//   final int sourcePrice;
//   final int destinationPrice;

//   int get profit => destinationPrice - sourcePrice;
// }

// int? recentPriceAt({
//   required String tradeSymbol,
//   required String marketplaceSymbol,
// }) {
//   return null;
// }

// Stream<Market> getAllMarkets(
//   Api api,
//   List<Waypoint> systemWaypoints,
// ) async* {
//   for (final waypoint in systemWaypoints) {
//     if (!waypoint.hasMarketplace) {
//       continue;
//     }
//     final response =
//         await api.systems.getMarket(waypoint.systemSymbol, waypoint.symbol);
//     yield response!.data;
//   }
// }

// Iterable<_Deal> _allDeals(Market localMarket,
//    List<Market> otherMarkets) sync* {
//   for (final otherMarket in otherMarkets) {
//     for (final wanted in otherMarket.imports) {
//       for (final offered in localMarket.tradeGoods) {
//         if (wanted.symbol == offered.symbol) {
//           yield _Deal(
//             tradeSymbol: wanted.symbol,
//             destination: otherMarket.waypoint,
//             sourcePrice: offered.price,
//             destinationPrice: wanted.price,
//           );
//         }
//       }
//     }
//   }
// }

// Future<_Deal> findBestDeal(
//   Api api,
//   Ship ship,
//   Waypoint currentWaypoint,
//   List<Waypoint> systemWaypoints,
// ) async {
//   // Fetch all marketplace data
//   final allMarkets = await getAllMarkets(api, systemWaypoints).toList();
//   final localMarket =
//       allMarkets.firstWhere((m) => m.symbol == currentWaypoint.symbol);
//   final otherMarkets =
//       allMarkets.where((m) => m.symbol != localMarket.symbol);

//   final allDeals = _allDeals(localMarket, otherMarkets);
//   // Construct all possible deals.
//   // Get the list of trade symbols sold at this marketplace.
//   // Upload current prices at this market to the db.
//   // For each trade symbol, get the price at this marketplace.
//   // for (final tradeSymbol in tradeSymbols) {}
//   // For each trade symbol, get the price at the destination marketplace.
//   // Sort by assumed profit.
//   // If we don't have a destination price, assume 50th percentile.
//   // Deals are then sorted by profit, and we take the best one.

//   // If we don't have a percentile, match only export/import.
//   // Picking at random from the matchable exports?
//   // Or picking the shortest distance?
// }

/// One loop of the trading logic
Future<DateTime?> advanceTrader(
  Api api,
  DataStore db,
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
      shipInfo(ship, 'Refueling');
      await api.fleet.refuelShip(ship.symbol);
      return null;
    }
    final currentWaypoint =
        lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    if (currentWaypoint.hasMarketplace) {
      // Sell any cargo we can.
      await sellCargoAndLog(api, ship, where: _shouldSellItem);
      // final deal =
      //     await findBestDeal(api, ship, currentWaypoint, systemWaypoints);
      // await navigateTo(api, ship, deal.destination);
      throw UnimplementedError();
    } else {
      throw UnimplementedError();
    }
  }
  return null;
}

/// One loop of the logic.
Stream<DateTime> logicLoop(Api api, DataStore db) async* {
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
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
        final maybeWaitUntil =
            await advanceMiner(api, db, ship, systemWaypoints);
        if (maybeWaitUntil != null) {
          yield maybeWaitUntil;
        }
      } on ApiException catch (e) {
        final expiration = expirationFromApiException(e);
        if (expiration != null) {
          yield expiration;
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
  return false;
  // return myAgent.credits > 140000;
}

/// Run the logic loop forever.
/// Currently just sends ships to mine and sell ore.
Future<void> logic(Api api) async {
  final db = DataStore();
  await db.open();

  while (true) {
    final nextEventTimes = await logicLoop(api, db).toList();
    if (nextEventTimes.isNotEmpty) {
      final earliestWaitUntil =
          nextEventTimes.reduce((a, b) => a.isBefore(b) ? a : b);
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.now());
      logger.info(
        '⏱️ ${waitDuration.inSeconds}s until ${earliestWaitUntil.toLocal()}',
      );
      await Future<void>.delayed(earliestWaitUntil.difference(DateTime.now()));
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
