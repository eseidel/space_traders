import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

// Central command sets behavior for all ships.
// Groups ships into squads.
// Can hold queues of work to distribute among squads.
// Need to figure out what disableBehavior looks like for squads.

// Central command can also be responsible for deciding when to buy a ship
// and what type of ship to buy.

// Central command can also plan sourcing of modules for ships even
// across long distances to bring back mounts for our ships?

// Central command can also prioritize which ships get serviced based
// on some sort of priority function?  (e.g. earnings per request)

// Examples:
// Mining Squad
// - N miners
// - M haulers
// Decisions made as to if something should sell at the local market
// or be put on the hauler, or jettisoned?
// I guess if you're full you just keep surveying until a hauler comes?

// Exploration Squad
// - N explorers
// Work from a single queue of systems to explore.
// Are given new work based on proximity to systems in queue.

// Exploration Squad
// - N explorers
// Go and sit at the most important waypoints to watch (e.g. shipyards/markets)
// And scan them into our cache every N minutes.

// Trading Squad
// - N haulers?
// Work from a queue of deals so as not to over-saturate any one deal.
// Could estimate how much price is going to raise from a deal?

// Contract Squad
// - N haulers?
// Work from a single contract, but might source from multiple markets.
// instead of sending all of the haulers to the same market.  Again
// approximating how much price is going to raise from a deal?

@immutable
class _ShipTimeout {
  const _ShipTimeout(this.shipSymbol, this.behavior, this.timeout);

  final String shipSymbol;
  final Behavior behavior;
  final DateTime timeout;
}

/// Central command for the fleet.
class CentralCommand {
  /// Create a new central command.
  CentralCommand({
    required BehaviorCache behaviorCache,
    required ShipCache shipCache,
  })  : _behaviorCache = behaviorCache,
        _shipCache = shipCache;

  final Map<Behavior, DateTime> _behaviorTimeouts = {};
  final List<_ShipTimeout> _shipTimeouts = [];

  final BehaviorCache _behaviorCache;
  final ShipCache _shipCache;
  Duration _maxAgeForExplorerData = const Duration(days: 3);

  int _loops = 0;

  /// Returns true if contract trading is enabled.
  /// We will only accept and start new contracts when this is true.
  /// We will continue to deliver current contract deals even if this is false,
  /// but will not start new deals involving contracts.
  bool get isContractTradingEnabled => true;

  /// Minimum profit per second we will accept when trading.
  // Should set this based on the ship type and how much we expect to earn
  // from other sources (e.g. hauling mining goods?)
  int get minTraderProfitPerSecond => 7;

  /// Data older than this will be refreshed by explorers.
  /// Explorers will shorten this time if they run out of places to explore.
  Duration get maxAgeForExplorerData => _maxAgeForExplorerData;

  /// Shorten the max age for explorer data.
  Duration shortenMaxAgeForExplorerData() {
    return _maxAgeForExplorerData ~/= 2;
  }

  /// Give the central command a chance to run.
  void runCentralCommandLogic() {
    _loops++;
    if (_loops % 100 == 0) {}
    // Run every N loops.
    // Evaluate earnings for all ships over the last N minutes.
    // If we don't have enough data for a ship/squad, then skip it.
    // If we have enough data, then we can compute earnings per second.
    // If it's below some threshold, then we should move it to a system
    // we think might be more profitable.
    // - Check if we need to buy a new ship.
    // - Check if our miners are still at an optimal waypoint?
    // - Refresh MarketScan for deals?
    // - Refresh MarketScan for miners?
  }

  // To tell a given explorer what to do.
  // Figure out what squad they're in (are they watching a waypoint for us
  // or are they exploring? and if so what jump gate network?)
  // Then figure out what the next waypoint is for them to explore.
  // If we don't have a cache of places to explore, collect a list
  // of systems needing a visit.
  // If there still aren't any places to explore, then we need to see if there
  // is a place for them to watch.
  // If there still isn't, then we print a warning and have them idle.

  // Absolute dumbest thing:
  // - Get a request for a new system (because they're at a jump gate)
  // - Find systems with unexplored waypoints
  // - Remove all systems with probes currently there or targeting there.
  // - Pick the closest system to the current system.
  // - Send them there.

  // Will require moving the behavior state into the central command.

  // Otherwise, find a system to explore.

  /// Check if the given behavior is globally disabled.
  bool isBehaviorDisabled(Behavior behavior) {
    final expiration = _behaviorTimeouts[behavior];
    if (expiration == null) {
      return false;
    }
    if (DateTime.timestamp().isAfter(expiration)) {
      _behaviorTimeouts.remove(behavior);
      return false;
    }
    return true;
  }

  /// Check if the given behavior is disabled for the given ship.
  bool isBehaviorDisabledForShip(Ship ship, Behavior behavior) {
    bool matches(_ShipTimeout timeout) {
      return timeout.shipSymbol == ship.symbol && timeout.behavior == behavior;
    }

    final timeouts = _shipTimeouts.where(matches).toList();
    if (timeouts.isEmpty) {
      return false;
    }
    final expiration = timeouts.first.timeout;
    if (DateTime.timestamp().isAfter(expiration)) {
      _shipTimeouts.removeWhere(matches);
      return false;
    }
    return true;
  }

// Consider having a config file like:
// https://gist.github.com/whyando/fed97534173437d8234be10ac03595e0
// instead of having this dynamic behavior function.
// At the top of the file because I change this so often.
  /// What behavior should the given ship be doing?
  Behavior behaviorFor(
    Ship ship,
  ) {
    final disableBehaviors = <Behavior>[
      // Behavior.buyShip,
      // Behavior.trader,
      // Behavior.miner,
      // Behavior.idle,
      // Hangs too much for now.
      Behavior.explorer,
    ];

    // Probably want special behavior for the command ship when we
    // only have a few ships?

    final behaviors = {
      // TODO(eseidel): Evaluate based on expected value, not just order.
      ShipRole.COMMAND: [
        Behavior.buyShip,
        Behavior.trader,
        Behavior.miner,
      ],
      ShipRole.HAULER: [
        Behavior.trader,
        // Explorer is a hack here to get the haulers to move and try again.
        Behavior.explorer,
      ],
      ShipRole.EXCAVATOR: [Behavior.miner],
      ShipRole.SATELLITE: [Behavior.idle],
    }[ship.registration.role];
    if (behaviors != null) {
      for (final behavior in behaviors) {
        if (disableBehaviors.contains(behavior)) {
          continue;
        }
        if (!isBehaviorDisabled(behavior) &&
            !isBehaviorDisabledForShip(ship, behavior)) {
          return behavior;
        }
      }
    } else {
      logger.warn(
        '${ship.registration.role} has no specified behaviors, idling.',
      );
    }
    return Behavior.idle;
  }

  /// Disable the given behavior for an hour.
  // This should be a return type from the advance function instead of a
  // callback to the central command.
  Future<void> disableBehaviorForAll(
    Ship ship,
    Behavior behavior,
    String why,
    Duration timeout,
  ) async {
    final currentState = _behaviorCache.getBehavior(ship.symbol);
    if (currentState == null || currentState.behavior == behavior) {
      _behaviorCache.deleteBehavior(ship.symbol);
    } else {
      shipInfo(
        ship,
        'Not deleting ${currentState.behavior} for ${ship.symbol}.',
      );
    }

    shipWarn(
      ship,
      '$why Disabling $behavior for ${approximateDuration(timeout)}.',
    );

    final expiration = DateTime.timestamp().add(timeout);
    _behaviorTimeouts[behavior] = expiration;
  }

  /// Disable the given behavior for [ship] for [duration].
  Future<void> disableBehaviorForShip(
    Ship ship,
    Behavior behavior,
    String why,
    Duration duration,
  ) async {
    final currentState = _behaviorCache.getBehavior(ship.symbol);
    if (currentState == null || currentState.behavior == behavior) {
      _behaviorCache.deleteBehavior(ship.symbol);
    } else {
      shipInfo(
        ship,
        'Not deleting ${currentState.behavior} for ${ship.symbol}.',
      );
    }

    shipWarn(
      ship,
      '$why Disabling $behavior for ${ship.symbol} '
      'for ${approximateDuration(duration)}.',
    );

    final expiration = DateTime.timestamp().add(duration);
    _shipTimeouts.add(_ShipTimeout(ship.symbol, behavior, expiration));
  }

  /// Complete the current behavior for the given ship.
  Future<void> completeBehavior(String shipSymbol) async {
    return _behaviorCache.deleteBehavior(shipSymbol);
  }

  /// Set the [RoutePlan] for the ship.
  Future<void> setRoutePlan(Ship ship, RoutePlan routePlan) async {
    final state = _behaviorCache.getBehavior(ship.symbol)!
      ..routePlan = routePlan;
    _behaviorCache.setBehavior(ship.symbol, state);
  }

  /// Get the current [RoutePlan] for the given ship.
  RoutePlan? currentRoutePlan(Ship ship) {
    final state = _behaviorCache.getBehavior(ship.symbol);
    return state?.routePlan;
  }

  /// The [ship] has reached its destination.
  Future<void> reachedEndOfRoutePlan(Ship ship) async {
    final state = _behaviorCache.getBehavior(ship.symbol)!..routePlan = null;
    _behaviorCache.setBehavior(ship.symbol, state);
  }

  /// Record the given [transactions] for the current deal for [ship].
  Future<void> recordDealTransactions(
    Ship ship,
    List<Transaction> transactions,
  ) async {
    final behaviorState = getBehavior(ship.symbol)!;
    final deal = behaviorState.deal!;
    behaviorState.deal = deal.byAddingTransactions(transactions);
    await setBehavior(ship.symbol, behaviorState);
  }

  // This feels wrong.
  /// Load or create the right behavior state for [ship].
  Future<BehaviorState> loadBehaviorState(Ship ship) async {
    final state = _behaviorCache.getBehavior(ship.symbol);
    if (state == null) {
      final behavior = behaviorFor(ship);
      final newState = BehaviorState(
        ship.symbol,
        behavior,
      );
      _behaviorCache.setBehavior(ship.symbol, newState);
    }
    return _behaviorCache.getBehavior(ship.symbol)!;
  }

  // Needs refactoring, provided for compatiblity with old BehaviorManager.
  /// Get the current [BehaviorState] for the  [shipSymbol].
  BehaviorState? getBehavior(String shipSymbol) {
    return _behaviorCache.getBehavior(shipSymbol);
  }

  /// Set the current [BehaviorState] for the [shipSymbol].
  Future<void> setBehavior(String shipSymbol, BehaviorState state) async {
    _behaviorCache.setBehavior(shipSymbol, state);
  }

  /// Returns all systems containing explorers or explorer destinations.
  Iterable<CostedDeal> _dealsInProgress() sync* {
    for (final state in _behaviorCache.states) {
      final deal = state.deal;
      if (deal != null) {
        yield deal;
      }
    }
  }

  /// Procurment contracts converted to sell opps.
  Iterable<SellOpp> contractSellOpps(
    AgentCache agentCache,
    ContractCache contractCache,
  ) sync* {
    for (final contract in affordableContracts(agentCache, contractCache)) {
      for (final good in contract.terms.deliver) {
        yield SellOpp(
          marketSymbol: good.destinationSymbol,
          tradeSymbol: good.tradeSymbol,
          contractId: contract.id,
          price: _maxWorthwhileUnitPurchasePrice(contract, good),
          maxUnits:
              _remainingUnitsNeededForContract(contract, good.tradeSymbol),
        );
      }
    }
  }

  /// Find next deal for the given [ship], considering all deals in progress.
  Future<CostedDeal?> findNextDeal(
    AgentCache agentCache,
    ContractCache contractCache,
    MarketPrices marketPrices,
    SystemsCache systemsCache,
    SystemConnectivity systemConnectivity,
    JumpCache jumpCache,
    WaypointCache waypointCache,
    MarketCache marketCache,
    Ship ship, {
    required int maxJumps,
    required int maxTotalOutlay,
    required int maxWaypoints,
  }) async {
    final inProgress = _dealsInProgress().toList();
    // Avoid having two ships working on the same deal since by the time the
    // second one gets there the prices will have changed.
    // Note this does not check destination, so should still allow two
    // ships to work on the same contract.
    bool filter(CostedDeal deal) {
      return inProgress.every(
        (d) =>
            d.deal.sourceSymbol != deal.deal.sourceSymbol ||
            d.deal.tradeSymbol != deal.deal.tradeSymbol,
      );
    }

    /// This should decide if contract trading is enabled, and if it is
    /// include extra SellOpps for the contract goods.
    final extraSellOpps = isContractTradingEnabled
        ? contractSellOpps(agentCache, contractCache).toList()
        : <SellOpp>[];
    if (extraSellOpps.isNotEmpty) {
      final opp = extraSellOpps.first;
      logger.detail(
        'Including contract sell opp: ${opp.maxUnits} ${opp.tradeSymbol} '
        '@ ${creditsString(opp.price)} -> ${opp.marketSymbol}',
      );
    }

    final marketScan = scanNearbyMarkets(
      systemsCache,
      marketPrices,
      systemSymbol: ship.nav.systemSymbol,
      maxJumps: maxJumps,
      maxWaypoints: maxWaypoints,
    );
    final maybeDeal = await findDealForShip(
      marketPrices,
      systemsCache,
      systemConnectivity,
      jumpCache,
      marketScan,
      ship,
      maxJumps: maxJumps,
      maxTotalOutlay: maxTotalOutlay,
      extraSellOpps: extraSellOpps,
      filter: filter,
    );
    return maybeDeal;
  }

  /// Returns other systems containing ships with [behavior].
  Iterable<String> _otherSystemsWithBehavior(
    String thisShipSymbol,
    Behavior behavior,
  ) sync* {
    for (final state in _behaviorCache.states) {
      if (state.shipSymbol == thisShipSymbol) {
        continue;
      }
      if (state.behavior == behavior) {
        final destination = state.routePlan?.endSymbol;
        if (destination != null) {
          final parsed = parseWaypointString(destination);
          yield parsed.system;
        } else {
          final ship = _shipCache.ship(state.shipSymbol);
          yield ship.nav.systemSymbol;
        }
      }
    }
  }

  /// Returns all systems containing explorers or explorer destinations.
  Iterable<String> otherExplorerSystems(String thisShipSymbol) =>
      _otherSystemsWithBehavior(thisShipSymbol, Behavior.explorer);

  /// Returns all systems containing explorers or explorer destinations.
  Iterable<String> _otherTraderSystems(String thisShipSymbol) =>
      _otherSystemsWithBehavior(thisShipSymbol, Behavior.trader);

  int _countOfTypeInFleet(ShipType shipType) {
    final frameForType = {
      ShipType.ORE_HOUND: ShipFrameSymbolEnum.MINER,
      ShipType.PROBE: ShipFrameSymbolEnum.PROBE,
      ShipType.LIGHT_HAULER: ShipFrameSymbolEnum.LIGHT_FREIGHTER,
    }[shipType];
    if (frameForType == null) {
      return 0;
    }
    return _shipCache.frameCounts[frameForType] ?? 0;
  }

// This is a hack for now, we need real planning.
  /// Determine what type of ship to buy.
  // TODO(eseidel): This should consider pricing in it so that we can by
  // other ship types if they're not overpriced?
  ShipType? shipTypeToBuy(
    ShipyardPrices shipyardPrices,
    AgentCache agentCache, {
    required String waypointSymbol,
  }) {
    // We should buy a new ship when:
    // - We have request capacity to spare
    // - We have money to spare.
    // - We don't have better uses for the money (e.g. trading or modules)

    bool shipyardHas(ShipType shipType) {
      return shipyardPrices.recentPurchasePrice(
            shipyardSymbol: waypointSymbol,
            shipType: shipType,
          ) !=
          null;
    }

    // We should buy ships based on earnings of that ship type over the last
    // N hours?
    final systemSymbol = parseWaypointString(waypointSymbol).system;
    final hqSystemSymbol =
        parseWaypointString(agentCache.agent.headquarters).system;
    final inStartSystem = systemSymbol == hqSystemSymbol;

    final isEarlyGame = _shipCache.ships.length < 10;
    if (isEarlyGame) {
      if (!inStartSystem) {
        return null;
      }
      return ShipType.ORE_HOUND;
    }

    final targetCounts = {
      ShipType.ORE_HOUND: 30,
      ShipType.PROBE: 10,
      ShipType.LIGHT_HAULER: 50,
    };
    final typesToBuy = targetCounts.keys
        .where(
          (shipType) =>
              shipyardHas(shipType) &&
              (_countOfTypeInFleet(shipType) < targetCounts[shipType]!),
        )
        .toList();
    if (typesToBuy.isEmpty) {
      return null;
    }

    // We should buy haulers if we have fewer than X haulers idle.
    if (typesToBuy.contains(ShipType.LIGHT_HAULER)) {
      final idleHaulers = idleHaulerSymbols(_shipCache, _behaviorCache);
      if (idleHaulers.length < 4) {
        return ShipType.LIGHT_HAULER;
      }
    }
    // We should buy ore-hounds only if we're at a system which has good mining.
    if (typesToBuy.contains(ShipType.ORE_HOUND) && inStartSystem) {
      return ShipType.ORE_HOUND;
    }
    // We should buy probes if we have fewer than X of them.
    if (typesToBuy.contains(ShipType.PROBE)) {
      return ShipType.PROBE;
    }
    return null;
  }

  /// Visits the local shipyard if we're at a waypoint with a shipyard.
  /// Records shipyard data if needed.
  Future<void> visitLocalShipyard(
    Api api,
    ShipyardPrices shipyardPrices,
    AgentCache agentCache,
    Waypoint waypoint,
    Ship ship,
  ) async {
    if (!waypoint.hasShipyard) {
      return;
    }
    final shipyard = await getShipyard(api, waypoint);
    await recordShipyardDataAndLog(shipyardPrices, shipyard, ship);

    // Buy ship if we should.
    // For now lets always by haulers if we can afford them and we have
    // fewer than 3 haulers idle.
    await buyShipIfPossible(api, shipyardPrices, agentCache, ship);
  }

  /// What the max multiplier of median we would pay for a ship.
  double get maxMedianShipPriceMultipler => 1.1;

  /// How many haulers do we have?
  int get numberOfHaulers =>
      _shipCache.frameCounts[ShipFrameSymbolEnum.LIGHT_FREIGHTER] ?? 0;

  /// The minimum credits we should have to buy a new ship.
  int get minimumCreditsForTrading => numberOfHaulers * 10000;

  /// Attempt to buy a ship for the given [ship].
  Future<bool> buyShipIfPossible(
    Api api,
    ShipyardPrices shipyardPrices,
    AgentCache agentCache,
    Ship ship,
  ) async {
    if (isBehaviorDisabled(Behavior.buyShip) ||
        isBehaviorDisabledForShip(ship, Behavior.buyShip)) {
      return false;
    }

    // TODO(eseidel): Consider which ships are sold at this shipyard.

    // This assumes the ship in question is at a shipyard and already docked.
    final waypointSymbol = ship.nav.waypointSymbol;
    final shipType = shipTypeToBuy(
      shipyardPrices,
      agentCache,
      waypointSymbol: waypointSymbol,
    );
    // TODO(eseidel): This is wrong, this will disable buying for all
    // ships even though we might just be at a system where we don't need a ship
    // or can't afford one?
    if (shipType == null) {
      await disableBehaviorForAll(
        ship,
        Behavior.buyShip,
        'No ships needed.',
        const Duration(minutes: 10),
      );
      return false;
    }

    // Get our median price before updating shipyard prices.
    final medianPrice = shipyardPrices.medianPurchasePrice(shipType);
    if (medianPrice == null) {
      await disableBehaviorForAll(
        ship,
        Behavior.buyShip,
        'Failed to buy ship, no median price for $shipType.',
        const Duration(minutes: 10),
      );
      return false;
    }
    final maxMedianMultiplier = maxMedianShipPriceMultipler;
    final maxPrice = (medianPrice * maxMedianMultiplier).toInt();

    // We should only try to buy new ships if we have enough money to keep
    // our traders trading.
    final budget = agentCache.agent.credits - minimumCreditsForTrading;
    final credits = budget;
    if (credits < maxPrice) {
      await disableBehaviorForAll(
        ship,
        Behavior.buyShip,
        'Can not buy $shipType, budget $credits < max price $maxPrice.',
        const Duration(minutes: 10),
      );
      return false;
    }

    final recentPrice = shipyardPrices.recentPurchasePrice(
      shipyardSymbol: waypointSymbol,
      shipType: shipType,
    );
    if (recentPrice == null) {
      await disableBehaviorForShip(
        ship,
        Behavior.buyShip,
        'Shipyard at $waypointSymbol does not sell $shipType.',
        const Duration(minutes: 10),
      );
      return false;
    }

    final recentPriceString = creditsString(recentPrice);
    if (recentPrice > maxPrice) {
      await disableBehaviorForShip(
        ship,
        Behavior.buyShip,
        'Failed to buy $shipType at $waypointSymbol, '
        '$recentPriceString > max price $maxPrice.',
        const Duration(minutes: 10),
      );
      return false;
    }

    // Do we need to catch exceptions about insufficient credits?
    final result = await purchaseShipAndLog(
      api,
      _shipCache,
      agentCache,
      ship,
      waypointSymbol,
      shipType,
    );

    await disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Purchase of ${result.ship.symbol} ($shipType) successful!',
      const Duration(minutes: 10),
    );
    return true;
  }

  /// Returns the ship symbols working on [contract].
  Iterable<String> _shipSymbolsServicingContract(Contract contract) {
    return _behaviorCache.states
        .where((state) => state.deal?.contractId == contract.id)
        .map((state) => state.shipSymbol);
  }

  /// Computes the number of units needed to fulfill the given [contract].
  /// It should exclude units already spoken for by other ships, but doesn't
  /// yet.
  int _remainingUnitsNeededForContract(Contract contract, String tradeSymbol) {
    final shipSymbols = _shipSymbolsServicingContract(contract);
    final ships = _shipCache.ships.where((s) => shipSymbols.contains(s.symbol));
    // This is an over-estimation of the max units in flight since
    // ships might get to a destination and not buy a full load.
    final maxUnitsInFlight = ships.fold<int>(
      0,
      (sum, ship) => sum + ship.cargo.capacity,
    );
    final neededGood = contract.goodNeeded(tradeSymbol);
    return neededGood!.unitsRequired -
        neededGood.unitsFulfilled -
        maxUnitsInFlight;
  }

  /// Returns the symbol of the nearest mine to the given [ship].
  // This should probably return a "mining plan" instead, which includes
  // what type of mining this is, where the mine is, where the markets are?
  String? mineSymbolForShip(SystemsCache systemsCache, Ship ship) {
    final systemSymbol = ship.nav.systemSymbol;
    // Return the nearest mine to the ship for now?
    final systemWaypoints = systemsCache.waypointsInSystem(systemSymbol);
    return systemWaypoints.firstWhereOrNull((w) => w.canBeMined)?.symbol;
    // If the ship is in a system without a mine go to the HQ?

    // final mine = await nearestMineWithGoodMining(
    //   api,
    //   marketPrices,
    //   systemsCache,
    //   waypointCache,
    //   marketCache,
    //   currentWaypoint,
    //   maxJumps: maxJumps,
    //   tradeSymbol: 'PRECIOUS_STONES',
    // );
    // if (mine == null) {
    //   await centralCommand.disableBehaviorForShip(
    //     ship,
    //     Behavior.miner,
    //     'No good mining system found in '
    //     '$maxJumps radius of ${ship.nav.systemSymbol}.',
    //     const Duration(hours: 1),
    //   );
    //   return null;
    // }
  }

  /// Find a better destination for the given trader [ship].
  Future<String?> findBetterTradeLocation(
    SystemsCache systemsCache,
    SystemConnectivity systemConnectivity,
    JumpCache jumpCache,
    AgentCache agentCache,
    MarketPrices marketPrices,
    Ship ship, {
    required int maxJumps,
    required int maxWaypoints,
  }) async {
    final traderSystems = _otherTraderSystems(ship.symbol).toList();
    final search = _MarketSearch.start(
      marketPrices,
      systemsCache,
      avoidSystems: traderSystems.toSet(),
    );
    final placement = await _findBetterSystemForTrader(
      systemsCache,
      systemConnectivity,
      jumpCache,
      agentCache,
      marketPrices,
      search,
      ship,
      maxJumps: maxJumps,
      maxWaypoints: maxWaypoints,
      profitPerSecondThreshold: minTraderProfitPerSecond,
    );
    return placement?.destinationSymbol;
  }
}

int _maxWorthwhileUnitPurchasePrice(
  Contract contract,
  ContractDeliverGood good,
) {
  // To compute all of this we need to:
  // 1. First estimate the total cost of the contract goods based on median
  //    market prices.
  // 2. Then compare to total revenue of the contract to get expected profit. We
  //    could also add our own minimum profit here if needed?
  // 3. Then distribute profit evenly across all goods based on total price
  //    weight of the goods.
  // 4. The compute the price + profit expected for each good.
  // 5. Then take the remaining units needed for each good time price + profit.

  final totalPayment =
      contract.terms.payment.onAccepted + contract.terms.payment.onFulfilled;
  // TODO(eseidel): "break even" should include a minimum margin.
  return totalPayment ~/ good.unitsRequired;
}

/// Returns the minimum float required to complete this contract.
int _minimumFloatRequired(Contract contract) {
  assert(
    contract.type == ContractTypeEnum.PROCUREMENT,
    'Only procurement contracts are supported',
  );
  assert(
    contract.terms.deliver.length == 1,
    'Only contracts with a single deliver good are supported',
  );
  final good = contract.terms.deliver.first;
  // MaxUnitPrice is the max we'd pay, which isn't the max they're likely to
  // cost.  We could instead use median price of the good in question.
  final maxUnitPrice = _maxWorthwhileUnitPurchasePrice(contract, good);
  const creditsBuffer = 20000;
  final remainingUnits = good.unitsRequired - good.unitsFulfilled;
  // TODO(eseidel): 100000 is an arbitrary minimum we should remove!
  return max(100000, maxUnitPrice * remainingUnits + creditsBuffer);
}

/// Returns the contracts we should consider for trading.
/// This is a subset of the active contracts that we have enough money to
/// complete.
Iterable<Contract> affordableContracts(
  AgentCache agentCache,
  ContractCache contractsCache,
) {
  // We should only use the contract trader when we have enough credits to
  // complete the entire contract.  Otherwise we're just sinking credits into a
  // contract we can't complete yet when we could be using that money for other
  // trading.
  final credits = agentCache.agent.credits;
  return contractsCache.activeContracts
      .where((c) => _minimumFloatRequired(c) <= credits);
}

/// Compute the score for each market based on the distance of each good's
/// price from the median price.
Map<String, int> scoreMarketSystems(
  MarketPrices marketPrices, {
  int limit = 100,
}) {
  // Walk all markets in the market prices.  Get all goods for each market
  // compute the absolute distance for each good from the median price
  // sum up that value for the market and record that as the "market score".

  // First calculate median prices for all goods.
  final medianPurchasePrices = <String, int?>{};
  final medianSellPrices = <String, int?>{};
  for (final tradeSymbolEnum in TradeSymbol.values) {
    final tradeSymbol = tradeSymbolEnum.value;
    medianPurchasePrices[tradeSymbol] =
        marketPrices.medianPurchasePrice(tradeSymbol);
    medianSellPrices[tradeSymbol] = marketPrices.medianSellPrice(tradeSymbol);
  }

  final marketSystemScores = <String, int>{};
  for (final price in marketPrices.prices) {
    final market = price.waypointSymbol;
    final system = parseWaypointString(market).system;
    final medianPurchasePrice = medianPurchasePrices[price.symbol]!;
    final medianSellPrice = medianSellPrices[price.symbol]!;
    final purchaseScore = (price.purchasePrice - medianPurchasePrice).abs();
    final sellScore = (price.sellPrice - medianSellPrice).abs();
    final score = purchaseScore + sellScore;
    marketSystemScores[system] = (marketSystemScores[system] ?? 0) + score;
  }

  final sortedScores = marketSystemScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sortedScores.take(limit));
}

/// Returns the ship symbols for all idle haulers.
List<String> idleHaulerSymbols(
  ShipCache shipCache,
  BehaviorCache behaviorCache,
) {
  final haulerSymbols =
      shipCache.ships.where((s) => s.isHauler).map((s) => s.symbol);
  final idleBehaviors = [Behavior.idle, Behavior.explorer];
  final idleHaulerStates = behaviorCache.states
      .where((s) => haulerSymbols.contains(s.shipSymbol))
      .where((s) => idleBehaviors.contains(s.behavior))
      .toList();
  return idleHaulerStates.map((s) => s.shipSymbol).toList();
}

System? _closestSystem(
  SystemsCache systemsCache,
  System start,
  List<System> systems,
) {
  var bestDistance = double.infinity;
  System? bestSystem;
  for (final system in systems) {
    final distance = start.distanceTo(system);
    if (distance < bestDistance) {
      bestDistance = distance.toDouble();
      bestSystem = system;
    }
  }
  return bestSystem;
}

class _ShipPlacement {
  _ShipPlacement({
    required this.score,
    required this.distance,
    required this.profitPerSecond,
    required this.destinationSymbol,
  });

  final int score;
  final int distance;
  final int profitPerSecond;
  final String destinationSymbol;
}

class _MarketSearch {
  _MarketSearch({
    required this.marketSystems,
    required this.marketSystemScores,
    required this.claimedSystemSymbols,
  });

  factory _MarketSearch.start(
    MarketPrices marketPrices,
    SystemsCache systemsCache, {
    Set<String>? avoidSystems,
  }) {
    final marketSystemScores = scoreMarketSystems(marketPrices);
    final marketSystems =
        marketSystemScores.keys.map(systemsCache.systemBySymbol).toList();
    return _MarketSearch(
      marketSystems: marketSystems,
      marketSystemScores: marketSystemScores,
      claimedSystemSymbols: avoidSystems ?? {},
    );
  }

  final List<System> marketSystems;
  final Map<String, int> marketSystemScores;
  final Set<String> claimedSystemSymbols;

  System? closestAvailableSystem(
    SystemsCache systemsCache,
    System startSystem,
  ) {
    final availableSystems = marketSystems
        .where((system) => !claimedSystemSymbols.contains(system.symbol))
        .toList();
    return _closestSystem(systemsCache, startSystem, availableSystems);
  }

  void markUsed(System system) => claimedSystemSymbols.add(system.symbol);

  int scoreFor(String systemSymbol) => marketSystemScores[systemSymbol]!;
}

Future<_ShipPlacement?> _findBetterSystemForTrader(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  JumpCache jumpCache,
  AgentCache agentCache,
  MarketPrices marketPrices,
  _MarketSearch search,
  Ship ship, {
  required int maxJumps,
  required int maxWaypoints,
  required int profitPerSecondThreshold,
}) async {
  final shipSymbol = ship.symbol;
  final shipSystem = systemsCache.systemBySymbol(ship.nav.systemSymbol);
  while (true) {
    final closest = search.closestAvailableSystem(systemsCache, shipSystem);
    if (closest == null) {
      logger.info('No nearby markets for $shipSymbol');
      return null;
    }
    search.markUsed(closest);
    final score = search.scoreFor(closest.symbol);
    final scan = scanNearbyMarkets(
      systemsCache,
      marketPrices,
      systemSymbol: closest.symbol,
      maxJumps: maxJumps,
      maxWaypoints: maxWaypoints,
    );
    final systemJumpGate =
        systemsCache.jumpGateWaypointForSystem(closest.symbol)!;
    final deal = await findDealFor(
      marketPrices,
      systemsCache,
      systemConnectivity,
      jumpCache,
      scan,
      startSymbol: systemJumpGate.symbol,
      fuelCapacity: ship.fuel.capacity,
      cargoCapacity: ship.cargo.capacity,
      shipSpeed: ship.engine.speed,
      maxJumps: maxJumps,
      maxTotalOutlay: agentCache.agent.credits,
    );
    if (deal == null) {
      logger.info('No deal found for $shipSymbol at ${closest.symbol}');
      search.markUsed(closest);
      continue;
    }
    final profitPerSecond = deal.expectedProfitPerSecond;
    if (profitPerSecond < profitPerSecondThreshold) {
      logger.info('Profit per second too low for $shipSymbol at '
          '${closest.symbol}, $profitPerSecond < $profitPerSecondThreshold');
      search.markUsed(closest);
      continue;
    }
    final placement = _ShipPlacement(
      score: score,
      distance: shipSystem.distanceTo(closest),
      profitPerSecond: profitPerSecond,
      destinationSymbol: systemJumpGate.symbol,
    );
    return placement;
  }
}
