import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

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

// String _emojiForSellPrice(PriceData data, String tradeSymbol, int sellPrice)
// {
//   final percentile = data.percentileForSellPrice(tradeSymbol, sellPrice);
//   if (percentile == null) {
//     return '🤷';
//   }
//   if (percentile < 25) {
//     return '⏬';
//   }
//   if (percentile < 50) {
//     return '🔽';
//   }
//   if (percentile < 75) {
//     return '🔼';
//   }
//   return '⏫';
// }

String _stringForPriceDeviance(
  PriceData data,
  String tradeSymbol,
  int sellPrice,
  MarketTransactionTypeEnum type,
) {
  final median = type == MarketTransactionTypeEnum.SELL
      ? data.medianSellPrice(tradeSymbol)
      : data.medianPurchasePrice(tradeSymbol);
  if (median == null) {
    return '🤷';
  }
  final diff = sellPrice - median;
  if (diff == 0) {
    return '👌';
  }
  final percentOff = (diff / median * 100).round();

  final lowColor =
      type == MarketTransactionTypeEnum.SELL ? lightRed : lightGreen;
  final highColor =
      type == MarketTransactionTypeEnum.SELL ? lightGreen : lightRed;

  if (diff < 0) {
    return lowColor.wrap('$percentOff% ${creditsString(diff)}')!;
  }
  return highColor.wrap('+$percentOff% ${creditsString(diff)}')!;
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
    final priceEmoji = _stringForPriceDeviance(
      priceData,
      transaction.tradeSymbol,
      transaction.pricePerUnit,
      transaction.type,
    );
    shipInfo(
      ship,
      '🤝 ${transaction.units.toString().padLeft(2)} '
      // Could use TradeSymbol.values.reduce() to find the longest symbol.
      '${transaction.tradeSymbol.padRight(18)} '
      '$priceEmoji per, '
      '${transaction.units.toString().padLeft(2)} x '
      '${creditsString(transaction.pricePerUnit).padLeft(3)} = '
      '${creditsString(transaction.totalPrice).padLeft(3)} -> '
      // Always want the 'c' after the credits.
      '🏦 ${creditsString(agent.credits)}',
    );
    newCargo = response.cargo;
  }
  return newCargo;
}

/// One loop of the mining logic
Future<DateTime?> advanceMiner(
  Api api,
  DataStore db,
  PriceData priceData,
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
  }
  if (ship.isDocked) {
    if (ship.fuel.current < ship.fuel.capacity) {
      shipInfo(ship, 'Refueling');
      await api.fleet.refuelShip(ship.symbol);
    }
    final currentWaypoint =
        lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
    if (currentWaypoint.isAsteroidField) {
      // If we still have space, mine.
      // It's not worth potentially waiting a minute just to get one piece of
      // cargo if we're going to sell it right away here.
      // Hence selling when we're down to 5 or fewer spaces left.
      if (ship.availableSpace > 5) {
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
        await sellCargoAndLog(api, priceData, ship, where: _shouldSellItem);
      }
    } else {
      // Fulfill contract if we have one.
      // Otherwise, sell ore.
      await sellCargoAndLog(api, priceData, ship, where: _shouldSellItem);
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

_ShipLogic _logicFor(Ship ship, ContractDeliverGood? maybeGoods) {
  if (maybeGoods != null && ship.engine.speed > 20) {
    return _ShipLogic.trader;
  }
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
Future<DateTime?> advanceTrader(
  Api api,
  DataStore db,
  PriceData priceData,
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
      await sellCargoAndLog(api, priceData, ship, where: _shouldSellItem);
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

/// One loop of the trading logic
Future<DateTime?> advanceContractTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Ship ship,
  List<Waypoint> systemWaypoints,
  Contract contract,
  ContractDeliverGood goods,
) async {
  if (ship.isInTransit) {
    // Do nothing for now.
    return ship.nav.route.arrival;
  }
  if (!ship.isDocked) {
    await api.fleet.dockShip(ship.symbol);
  }
  if (ship.fuel.current < ship.fuel.capacity) {
    shipInfo(ship, 'Refueling');
    await api.fleet.refuelShip(ship.symbol);
  }

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
        'Delivered $units '
        '(${deliver.unitsFulfilled} / ${deliver.unitsRequired}) '
        '${goods.tradeSymbol} to ${goods.destinationSymbol}',
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
    final markets = _marketsWithExport(goods.tradeSymbol, allMarkets);
    // TODO(eseidel): for now, go back to asteroid field.
    final marketSymbol = markets.firstOrNull?.symbol ?? 'X1-ZA40-99095A';
    final destination = lookupWaypoint(marketSymbol, systemWaypoints);
    shipInfo(ship, 'Navigating to ${destination.symbol}');
    final response = await navigateTo(api, ship, destination);
    return response.nav.route.arrival;
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
      // Sell everything we have.
      shipInfo(ship, 'Selling everything except ${goods.tradeSymbol}');
      final cargo = await sellCargoAndLog(
        api,
        priceData,
        ship,
        where: (s) => s != goods.tradeSymbol,
      );
      if (cargo.availableSpace > 0) {
        shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
        // Buy a full stock of contract goal.
        final request = PurchaseCargoRequest(
          symbol: goods.tradeSymbol,
          units: cargo.availableSpace,
        );
        final response = await api.fleet
            .purchaseCargo(ship.symbol, purchaseCargoRequest: request);

        final transaction = response!.data.transaction;
        final agent = response.data.agent;
        final priceEmoji = _stringForPriceDeviance(
          priceData,
          transaction.tradeSymbol,
          transaction.pricePerUnit,
          transaction.type,
        );
        shipInfo(
          ship,
          '💸 ${transaction.units.toString().padLeft(2)} '
          // Could use TradeSymbol.values.reduce() to find the longest symbol.
          '${transaction.tradeSymbol.padRight(18)} '
          '$priceEmoji per, '
          '${transaction.units.toString().padLeft(2)} x '
          '${creditsString(transaction.pricePerUnit).padLeft(3)} = '
          '${creditsString(transaction.totalPrice).padLeft(3)} -> '
          // Always want the 'c' after the credits.
          '🏦 ${creditsString(agent.credits)}',
        );
      }
    }
    // Regardless, navigate to contract destination.
    final destination =
        lookupWaypoint(goods.destinationSymbol, systemWaypoints);
    shipInfo(ship, 'Navigating to ${destination.symbol}');
    final response = await navigateTo(api, ship, destination);
    return response.nav.route.arrival;
  }
  return null;
}

/// One loop of the logic.
Stream<DateTime> logicLoop(Api api, DataStore db, PriceData priceData) async* {
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final hq = parseWaypointString(agentResult.data.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system).toList();
  final myShips = await allMyShips(api).toList();
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
    return; // Fetch ship lists again.
  }

  // printShips(myShips, systemWaypoints);
  // loop over all mining ships and advance them.
  for (final ship in myShips) {
    final logic = logicByShipSymbol[ship.symbol]!;

    switch (logic) {
      case _ShipLogic.trader:
        // We currently only trigger trader logic if we have a contract.
        final maybeWaitUntil = await advanceContractTrader(
          api,
          db,
          priceData,
          ship,
          systemWaypoints,
          contract!,
          maybeGoods!,
        );
        if (maybeWaitUntil != null) {
          yield maybeWaitUntil;
        }
      case _ShipLogic.miner:
        try {
          final maybeWaitUntil =
              await advanceMiner(api, db, priceData, ship, systemWaypoints);
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

  final priceData = await PriceData.load();

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

  while (true) {
    final nextEventTimes = await logicLoop(api, db, priceData).toList();
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
