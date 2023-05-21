import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/ship_waiter.dart';

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
Future<ShipCargo> sellCargoAndLog(
  Api api,
  PriceData priceData,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async {
  var newCargo = ship.cargo;
  if (ship.cargo.inventory.isEmpty) {
    shipInfo(ship, 'No cargo to sell');
    return newCargo;
  }

  await for (final response in sellCargo(api, ship, where: where)) {
    final transaction = response.transaction;
    final agent = response.agent;
    logTransaction(ship, priceData, agent, transaction);
    newCargo = response.cargo;
  }
  return newCargo;
}

/// refuel the ship if needed and log the transaction
Future<void> refuelIfNeededAndLog(
  Api api,
  PriceData priceData,
  Agent agent,
  Ship ship,
) async {
  // One fuel bought from the market is 100 units of fuel in the ship.
  // For repeated short trips, avoiding buying fuel when we're close to full.
  if (ship.fuel.current >= (ship.fuel.capacity - 100)) {
    return;
  }
  // shipInfo(ship, 'Refueling (${ship.fuel.current} / ${ship.fuel.capacity})');
  final responseWrapper = await api.fleet.refuelShip(ship.symbol);
  final response = responseWrapper!.data;
  logTransaction(
    ship,
    priceData,
    agent,
    response.transaction,
    transactionEmoji: '⛽',
  );
}

Future<void> _dockIfNeeded(Api api, Ship ship) async {
  if (ship.isOrbiting) {
    shipInfo(ship, 'Docking at ${ship.nav.waypointSymbol}');
    await api.fleet.dockShip(ship.symbol);
  }
}

Future<void> _undockIfNeeded(Api api, Ship ship) async {
  if (ship.isDocked) {
    shipInfo(ship, 'Moving to orbit at ${ship.nav.waypointSymbol}');
    await api.fleet.orbitShip(ship.symbol);
  }
}

/// Navigate to the waypoint and log to the ship's log
Future<DateTime> navigateToAndLog(
  Api api,
  Ship ship,
  Waypoint waypoint,
) async {
  final result = await navigateTo(api, ship, waypoint);
  final flightTime = result.nav.route.arrival.difference(DateTime.now());
  // Could log used Fuel. result.fuel.fuelConsumed
  shipInfo(
    ship,
    '🛫 to ${waypoint.symbol} (${_durationString(flightTime)})',
  );
  return result.nav.route.arrival;
}

/// Either loads a cached survey set or creates a new one if we have a surveyor.
Future<SurveySet?> loadOrCreateSurveySetIfPossible(
  Api api,
  DataStore db,
  Ship ship,
) async {
  final cachedSurveySet = await loadSurveySet(db, ship.nav.waypointSymbol);
  if (cachedSurveySet != null) {
    return cachedSurveySet;
  }
  if (!ship.hasSurveyor) {
    return null;
  }
  // Survey
  final response = await api.fleet.createSurvey(ship.symbol);
  final survey = response!.data;
  final surveySet = SurveySet(
    waypointSymbol: ship.nav.waypointSymbol,
    surveys: survey.surveys,
  );
  await saveSurveySet(db, surveySet);
  shipInfo(ship, 'Surveyed ${ship.nav.waypointSymbol}');
  return null;
}

Survey? _chooseBestSurvey(SurveySet? surveySet) {
  if (surveySet == null) {
    return null;
  }
  // Each Survey can have multiple deposits.  The survey itself has a
  // size.  We should probably choose the most valuable ore based
  // on market price and then choose the largest deposit of that ore?
  return surveySet.surveys.firstOrNull;
}

/// One loop of the mining logic
Future<DateTime?> advanceMiner(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
) async {
  if (ship.isInTransit) {
    // Just go back to sleep until the ship is done flying.
    return ship.nav.route.arrival;
  }
  final currentWaypoint =
      lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
  if (currentWaypoint.isAsteroidField) {
    // If we still have space, mine.
    // It's not worth potentially waiting a minute just to get one piece of
    // cargo if we're going to sell it right away here.
    // Hence selling when we're down to 10 or fewer spaces.
    if (ship.availableSpace > 10) {
      // Load a survey set, or if we have surveying capabilities, survey.
      final surveySet = await loadOrCreateSurveySetIfPossible(api, db, ship);
      final maybeSurvey = _chooseBestSurvey(surveySet);
      await _undockIfNeeded(api, ship);
      final response = await extractResources(api, ship, survey: maybeSurvey);
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
      return response.cooldown.expiration;
    } else {
      // Is docking required to refuel and sell?
      await _dockIfNeeded(api, ship);
      await refuelIfNeededAndLog(api, priceData, agent, ship);

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
      await sellCargoAndLog(api, priceData, ship, where: _shouldSellItem);
    }
  } else {
    // Fulfill contract if we have one.
    // Otherwise, sell ore.
    await _dockIfNeeded(api, ship);
    await sellCargoAndLog(api, priceData, ship, where: _shouldSellItem);
    // Otherwise return to asteroid.
    final asteroidField = systemWaypoints.firstWhere((w) => w.isAsteroidField);
    return navigateToAndLog(api, ship, asteroidField);
  }
  return null;
}

_ShipLogic _logicFor(Ship ship, ContractDeliverGood? maybeGoods) {
  // if (maybeGoods != null && ship.engine.speed > 20) {
  //   return _ShipLogic.trader;
  // }
  // Could check if it has a mining laser or ship.isExcavator
  return _ShipLogic.miner;
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

/// Returns Market objects for all passed in waypoints.
Stream<Market> getAllMarkets(
  Api api,
  List<Waypoint> systemWaypoints,
) async* {
  for (final waypoint in systemWaypoints) {
    if (!waypoint.hasMarketplace) {
      continue;
    }
    final response =
        await api.systems.getMarket(waypoint.systemSymbol, waypoint.symbol);
    yield response!.data;
  }
}

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
// Future<DateTime?> advanceTrader(
//   Api api,
//   DataStore db,
//   PriceData priceData,
//   Agent agent,
//   Ship ship,
//   List<Waypoint> systemWaypoints,
// ) async {
//   if (ship.isInTransit) {
//     // Do nothing for now.
//     return ship.nav.route.arrival;
//   }
//   await _dockIfNeeded(api, ship);
//   await refuelIfNeededAndLog(api, priceData, agent, ship);
//   final currentWaypoint =
//       lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
//   if (currentWaypoint.hasMarketplace) {
//     // Sell any cargo we can.
//     await sellCargoAndLog(api, priceData, ship, where: _shouldSellItem);
//     // final deal =
//     //     await findBestDeal(api, ship, currentWaypoint, systemWaypoints);
//     // await navigateToAndLog(api, ship, deal.destination);
//     throw UnimplementedError();
//   }
//   throw UnimplementedError();
// }

enum _ShipLogic {
  trader,
  miner,
}

List<Market> _marketsWithExport(
  String tradeSymbol,
  List<Market> markets,
) {
  return markets
      .where((m) => m.exports.any((e) => e.symbol.value == tradeSymbol))
      .toList();
}

List<Market> _marketsWithExchange(
  String tradeSymbol,
  List<Market> markets,
) {
  return markets
      .where((m) => m.exchange.any((e) => e.symbol.value == tradeSymbol))
      .toList();
}

String _durationString(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
}

/// One loop of the trading logic
Future<DateTime?> advanceContractTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
  Contract contract,
  ContractDeliverGood goods,
) async {
  if (ship.isInTransit) {
    // Go back to sleep until we arrive.
    return ship.nav.route.arrival;
  }
  await _dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(api, priceData, agent, ship);
  final currentWaypoint =
      lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);

  final allMarkets = await getAllMarkets(api, systemWaypoints).toList();

  // If we're at our contract destination.
  if (currentWaypoint.symbol == goods.destinationSymbol) {
    final units = ship.countUnits(goods.tradeSymbol);
    if (units > 0) {
      // And we have the desired cargo.
      final request = DeliverContractRequest(
        shipSymbol: ship.symbol,
        tradeSymbol: goods.tradeSymbol,
        units: units,
      );
      final response = await api.contracts
          .deliverContract(contract.id, deliverContractRequest: request);
      final updatedContract = response!.data.contract;
      final deliver = updatedContract.goodNeeded(goods.tradeSymbol)!;
      shipInfo(
        ship,
        'Delivered $units ${goods.tradeSymbol} '
        'to ${goods.destinationSymbol}; '
        '${deliver.unitsFulfilled}/${deliver.unitsRequired}, '
        '${_durationString(contract.timeUntilDeadline)} to deadline',
      );
      // Update our cargo counts after fullfilling the contract.
      ship.cargo = response.data.cargo;

      // If we've delivered enough, complete the contract.
      if (deliver.amountNeeded <= 0) {
        await api.contracts.fulfillContract(contract.id);
        shipInfo(ship, 'Contract complete!');
        // Go back to mining.
        return null;
      }
    }
    // Sell anything we have.
    await sellCargoAndLog(api, priceData, ship);
    // nav to place nearby exporting our contract goal.
    var markets = _marketsWithExport(goods.tradeSymbol, allMarkets);
    if (markets.isEmpty) {
      markets = _marketsWithExchange(goods.tradeSymbol, allMarkets);
    }
    final marketSymbol = markets.firstOrNull?.symbol;
    final destination = lookupWaypoint(marketSymbol!, systemWaypoints);
    return navigateToAndLog(api, ship, destination);
  }

  // Otherwise if we're not at our contract destination.
  // And it has a market.
  if (currentWaypoint.hasMarketplace) {
    final market = lookupMarket(currentWaypoint.symbol, allMarkets);
    final maybeGood = market.tradeGoods
        .firstWhereOrNull((g) => g.symbol == goods.tradeSymbol);
    final medianPurchasePrice =
        priceData.medianPurchasePrice(goods.tradeSymbol);
    // And our contract goal is selling < market.
    // Or we don't know what "market" price is.
    if (maybeGood != null &&
        (medianPurchasePrice == null ||
            maybeGood.purchasePrice < medianPurchasePrice)) {
      // Sell everything we have except the contract goal.
      final cargo = await sellCargoAndLog(
        api,
        priceData,
        ship,
        where: (s) => s != goods.tradeSymbol,
      );
      if (cargo.availableSpace > 0) {
        // shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
        // Buy a full stock of contract goal.
        final request = PurchaseCargoRequest(
          symbol: goods.tradeSymbol,
          units: cargo.availableSpace,
        );
        final response = await api.fleet
            .purchaseCargo(ship.symbol, purchaseCargoRequest: request);
        final transaction = response!.data.transaction;
        final agent = response.data.agent;
        logTransaction(ship, priceData, agent, transaction);
      }
    }
  }
  // Regardless, navigate to contract destination.
  final destination = lookupWaypoint(goods.destinationSymbol, systemWaypoints);
  return navigateToAndLog(api, ship, destination);
}

Future<DateTime?> _advanceShip(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
  _ShipLogic logic,
  Contract? contract,
  ContractDeliverGood? maybeGoods,
) async {
  switch (logic) {
    case _ShipLogic.trader:
      // We currently only trigger trader logic if we have a contract.
      return advanceContractTrader(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
        contract!,
        maybeGoods!,
      );
    case _ShipLogic.miner:
      try {
        // This await is very important, if it's not present, exceptions won't
        // be caught until some outer await.
        return await advanceMiner(
          api,
          db,
          priceData,
          agent,
          ship,
          systemWaypoints,
        );
      } on ApiException catch (e) {
        // This handles the ship (reactor?) cooldown exception which we can
        // get when running the script fresh with no state while a ship is
        // still on cooldown from a previous run.
        final expiration = expirationFromApiException(e);
        if (expiration != null) {
          return expiration;
        }
        rethrow;
      }
  }
}

/// One loop of the logic.
Future<void> logicLoop(
  Api api,
  DataStore db,
  PriceData priceData,
  ShipWaiter waiter,
) async {
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final hq = parseWaypointString(agentResult.data.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system).toList();
  final myShips = await allMyShips(api).toList();
  waiter.updateForShips(myShips);
  final contracts = await allMyContracts(api).toList();
  if (contracts.length > 1) {
    throw UnimplementedError();
  }
  final contract = contracts.firstOrNull;
  final maybeGoods = contract?.terms.deliver.firstOrNull;

  final logicByShipSymbol = <String, _ShipLogic>{
    for (final ship in myShips) ship.symbol: _logicFor(ship, maybeGoods)
  };

  if (shouldPurchaseMiner(agent, myShips)) {
    logger.info('Purchasing mining drone.');
    final shipyardWaypoint = systemWaypoints.firstWhere((w) => w.hasShipyard);
    final purchaseResponse =
        await purchaseShip(api, ShipType.MINING_DRONE, shipyardWaypoint.symbol);
    logger.info('Purchased ${purchaseResponse.ship.symbol}');
    return; // Fetch ship lists again with no wait.
  }

  // printShips(myShips, systemWaypoints);
  // loop over all mining ships and advance them.
  for (final ship in myShips) {
    final previousWait = waiter.waitUntil(ship.symbol);
    if (previousWait != null) {
      continue;
    }
    final logic = logicByShipSymbol[ship.symbol]!;
    final waitUntil = await _advanceShip(
      api,
      db,
      priceData,
      agent,
      ship,
      systemWaypoints,
      logic,
      contract,
      maybeGoods,
    );
    waiter.updateWaitUntil(ship.symbol, waitUntil);
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
Future<void> logic(Api api, DataStore db, PriceData priceData) async {
  final contractsResponse = await api.contracts.getContracts();
  final contracts = contractsResponse!.data;

  for (final contract in contracts) {
    if (!contract.accepted) {
      await api.contracts.acceptContract(contract.id);
      logger
        ..info('Accepted: ${contractDescription(contract)}.')
        ..info(
          'received ${creditsString(contract.terms.payment.onAccepted)}',
        );
    }
  }

  final waiter = ShipWaiter();

  while (true) {
    await logicLoop(api, db, priceData, waiter);

    final earliestWaitUntil = waiter.earliestWaitUntil();
    if (earliestWaitUntil != null) {
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
