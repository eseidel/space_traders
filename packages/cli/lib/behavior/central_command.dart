import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/deliver.dart';
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

  final ShipSymbol shipSymbol;
  final Behavior behavior;
  final DateTime timeout;
}

/// Mounts template for a ship.
class ShipTemplate {
  /// Create a new ship template.
  const ShipTemplate({
    required this.frameSymbol,
    required this.mounts,
  });

  /// Frame type that this template is for.
  final ShipFrameSymbolEnum frameSymbol;

  /// Mounts that this template has.
  final Map<ShipMountSymbolEnum, int> mounts;
}

// According to SAF:
// Surveyor with 2x mk2s and miners with 2x mk2 + 1x mk1

final _templates = [
  const ShipTemplate(
    frameSymbol: ShipFrameSymbolEnum.MINER,
    mounts: {
      ShipMountSymbolEnum.MINING_LASER_II: 1,
      ShipMountSymbolEnum.MINING_LASER_I: 1,
      ShipMountSymbolEnum.SURVEYOR_I: 1,
    },
  )
];

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
  int minTraderProfitPerSecond(Ship ship) {
    if (ship.registration.role == ShipRole.COMMAND) {
      return 6;
    }
    return 7;
  }

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

  /// What template should we use for the given ship?
  ShipTemplate? templateForShip(Ship ship) {
    final frameSymbol = ship.frame.symbol;
    return _templates.firstWhereOrNull((e) => e.frameSymbol == frameSymbol);
  }

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
      return timeout.shipSymbol == ship.shipSymbol &&
          timeout.behavior == behavior;
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
    if (ship.isOutOfFuel) {
      return Behavior.idle;
    }

    final disableBehaviors = <Behavior>[
      // Behavior.buyShip,
      // Behavior.trader,
      // Hack becuase mining is so bad towards end game.
      // Behavior.miner,
      // Behavior.idle,
      // Hangs too much for now.
      // Behavior.explorer,
    ];

    // Probably want special behavior for the command ship when we
    // only have a few ships?

    final behaviors = {
      // TODO(eseidel): Evaluate based on expected value, not just order.
      // Should mine until we have one ore-hound, then switch to survey-only?

      ShipRole.COMMAND: [
        Behavior.buyShip,
        // Will only trade if we can make 6/s or more.
        // There are commonly 20c/s trades in the starting system, and at
        // the minimum we want to accept the contract.
        // Might want to consider limiting to short trades (< 5 mins) to avoid
        // tying up capital early.
        Behavior.trader,
        // Early on the command ship makes about 5c/s vs.
        // ore hounds making 6c/s.
        Behavior.miner,
      ],
      // Haulers are terrible explorers, but early game we just need
      // things mapping.
      ShipRole.HAULER: [Behavior.trader, Behavior.explorer],
      ShipRole.EXCAVATOR: [Behavior.miner],
      ShipRole.SATELLITE: [Behavior.explorer],
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
  void disableBehaviorForAll(
    Ship ship,
    Behavior behavior,
    String why,
    Duration timeout,
  ) {
    final shipSymbol = ship.shipSymbol;
    final currentState = _behaviorCache.getBehavior(shipSymbol);
    if (currentState == null || currentState.behavior == behavior) {
      _behaviorCache.deleteBehavior(shipSymbol);
    } else {
      shipInfo(ship, 'Not deleting ${currentState.behavior} for $shipSymbol.');
    }

    shipWarn(
      ship,
      '$why Disabling $behavior for ${approximateDuration(timeout)}.',
    );

    final expiration = DateTime.timestamp().add(timeout);
    _behaviorTimeouts[behavior] = expiration;
  }

  /// Disable the given behavior for [ship] for [duration].
  void disableBehaviorForShip(
    Ship ship,
    Behavior behavior,
    String why,
    Duration duration,
  ) {
    final shipSymbol = ship.shipSymbol;
    final currentState = _behaviorCache.getBehavior(shipSymbol);
    if (currentState == null || currentState.behavior == behavior) {
      _behaviorCache.deleteBehavior(shipSymbol);
    } else {
      shipInfo(ship, 'Not deleting ${currentState.behavior} for $shipSymbol.');
    }

    shipWarn(
      ship,
      '$why Disabling $behavior for $shipSymbol '
      'for ${approximateDuration(duration)}.',
    );

    final expiration = DateTime.timestamp().add(duration);
    _shipTimeouts.add(_ShipTimeout(ship.shipSymbol, behavior, expiration));
  }

  /// Complete the current behavior for the given ship.
  void completeBehavior(ShipSymbol shipSymbol) {
    return _behaviorCache.deleteBehavior(shipSymbol);
  }

  /// Returns any mount that's been queued for adding to this ship.
  ShipMountSymbolEnum? getMountToAdd(ShipSymbol shipSymbol) {
    final state = _behaviorCache.getBehavior(shipSymbol);
    return state?.mountToAdd;
  }

  /// Saves the given mount to be added to the ship.
  void claimMount(ShipSymbol shipSymbol, ShipMountSymbolEnum mountSymbol) {
    final state = _behaviorCache.getBehavior(shipSymbol);
    if (state == null) {
      logger.warn('No state for $shipSymbol');
      return;
    }
    state.mountToAdd = mountSymbol;
  }

  /// Returns the delivery ship bringing the mounts.
  Ship? getDeliveryShip(ShipSymbol shipSymbol, TradeSymbol item) {
    final deliveryShip = _shipCache.ships.first;
    final deliveryState = getBehavior(deliveryShip.shipSymbol);
    if (deliveryState?.behavior != Behavior.deliver) {
      return null;
    }
    // Check if it's at the shipyard?
    return deliveryShip;
  }

  /// Returns the counts of mounts already claimed.
  Map<ShipMountSymbolEnum, int> claimedMounts() {
    final claimed = <ShipMountSymbolEnum, int>{};
    for (final state in _behaviorCache.states) {
      final behavior = state.behavior;
      if (behavior != Behavior.changeMounts) {
        continue;
      }
      final mountSymbol = state.mountToAdd;
      if (mountSymbol == null) {
        continue;
      }
      claimed[mountSymbol] = (claimed[mountSymbol] ?? 0) + 1;
    }
    return claimed;
  }

  /// Returns the number of mounts available at the waypoint.
  Map<ShipMountSymbolEnum, int> unclaimedMountsAt(WaypointSymbol waypoint) {
    // Get all the ships at that symbol
    final ships = _shipCache.ships
        .where((s) => s.waypointSymbol == waypoint && !s.isInTransit);

    // That have behavior delivery.
    final counts = <ShipMountSymbolEnum, int>{};
    for (final ship in ships) {
      final state = _behaviorCache.getBehavior(ship.shipSymbol);
      if (state == null || state.behavior != Behavior.deliver) {
        continue;
      }
      final inventory = countMountsInInventory(ship);
      for (final entry in inventory.entries) {
        final mountSymbol = entry.key;
        final count = entry.value;
        final existingCount = counts[mountSymbol] ?? 0;
        counts[mountSymbol] = existingCount + count;
      }
    }
    // Get all the claimed mounts out of other ships states.
    final claimed = claimedMounts();
    for (final entry in claimed.entries) {
      final mountSymbol = entry.key;
      final count = entry.value;
      final existingCount = counts[mountSymbol] ?? 0;
      final remaining = existingCount - count;
      if (remaining <= 0) {
        if (remaining < 0) {
          logger.warn(
            'More mounts claimed than available: '
            '$mountSymbol $existingCount - $count',
          );
        }
        counts.remove(mountSymbol);
      } else {
        counts[mountSymbol] = remaining;
      }
    }
    return counts;
  }

  /// Set the [RoutePlan] for the ship.
  void setRoutePlan(Ship ship, RoutePlan routePlan) {
    final state = _behaviorCache.getBehavior(ship.shipSymbol)!
      ..routePlan = routePlan;
    _behaviorCache.setBehavior(ship.shipSymbol, state);
  }

  /// Get the current [RoutePlan] for the given ship.
  RoutePlan? currentRoutePlan(Ship ship) {
    final state = _behaviorCache.getBehavior(ship.shipSymbol);
    return state?.routePlan;
  }

  /// The [ship] has reached its destination.
  void reachedEndOfRoutePlan(Ship ship) {
    final state = _behaviorCache.getBehavior(ship.shipSymbol)!
      ..routePlan = null;
    _behaviorCache.setBehavior(ship.shipSymbol, state);
  }

  /// Record the given [transactions] for the current deal for [ship].
  Future<void> recordDealTransactions(
    Ship ship,
    List<Transaction> transactions,
  ) async {
    final behaviorState = getBehavior(ship.shipSymbol)!;
    final deal = behaviorState.deal!;
    behaviorState.deal = deal.byAddingTransactions(transactions);
    setBehavior(ship.shipSymbol, behaviorState);
  }

  // This feels wrong.
  /// Load or create the right behavior state for [ship].
  Future<BehaviorState> loadBehaviorState(Ship ship) async {
    final shipSymbol = ship.shipSymbol;
    final state = _behaviorCache.getBehavior(shipSymbol);
    if (state == null) {
      final behavior = behaviorFor(ship);
      final newState = BehaviorState(ship.shipSymbol, behavior);
      _behaviorCache.setBehavior(shipSymbol, newState);
    }
    return _behaviorCache.getBehavior(shipSymbol)!;
  }

  // Needs refactoring, provided for compatiblity with old BehaviorManager.
  /// Get the current [BehaviorState] for the  [shipSymbol].
  BehaviorState? getBehavior(ShipSymbol shipSymbol) {
    return _behaviorCache.getBehavior(shipSymbol);
  }

  /// Set the current [BehaviorState] for the [shipSymbol].
  void setBehavior(ShipSymbol shipSymbol, BehaviorState state) {
    _behaviorCache.setBehavior(shipSymbol, state);
  }

  /// Returns all deals in progress.
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
        final unitsNeeded = remainingUnitsNeededForContract(
          contract,
          good.tradeSymbolObject,
        );
        if (unitsNeeded > 0) {
          yield SellOpp(
            marketSymbol: good.destination,
            tradeSymbol: good.tradeSymbolObject,
            contractId: contract.id,
            price: _maxWorthwhileUnitPurchasePrice(contract, good),
            maxUnits: unitsNeeded,
          );
        }
      }
    }
  }

  /// Find next deal for the given [ship], considering all deals in progress.
  Future<CostedDeal?> findNextDeal(
    AgentCache agentCache,
    ContractCache contractCache,
    MarketPrices marketPrices,
    SystemsCache systemsCache,
    RoutePlanner routePlanner,
    Ship ship, {
    required int maxJumps,
    required int maxTotalOutlay,
    required int maxWaypoints,
    WaypointSymbol? overrideStartSymbol,
  }) async {
    final startSymbol = overrideStartSymbol ?? ship.waypointSymbol;
    final systemSymbol = overrideStartSymbol != null
        ? overrideStartSymbol.systemSymbol
        : ship.systemSymbol;

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
      systemSymbol: systemSymbol,
      maxJumps: maxJumps,
      maxWaypoints: maxWaypoints,
    );
    final maybeDeal = await findDealFor(
      marketPrices,
      systemsCache,
      routePlanner,
      marketScan,
      maxJumps: maxJumps,
      maxTotalOutlay: maxTotalOutlay,
      extraSellOpps: extraSellOpps,
      filter: filter,
      startSymbol: startSymbol,
      fuelCapacity: ship.fuel.capacity,
      // Currently using capacity, rather than availableSpace, since the
      // trader logic tries to clear out the hold.
      cargoCapacity: ship.cargo.capacity,
      shipSpeed: ship.engine.speed,
    );
    return maybeDeal;
  }

  Future<_ShipPlacement?> _findBetterSystemForTrader(
    SystemsCache systemsCache,
    RoutePlanner routePlanner,
    AgentCache agentCache,
    ContractCache contractCache,
    MarketPrices marketPrices,
    _MarketSearch search,
    Ship ship, {
    required int maxJumps,
    required int maxWaypoints,
    required int profitPerSecondThreshold,
  }) async {
    final shipSymbol = ship.symbol;
    final shipSystem = systemsCache.systemBySymbol(ship.systemSymbol);
    while (true) {
      final closest = search.closestAvailableSystem(systemsCache, shipSystem);
      if (closest == null) {
        logger.info('No nearby markets for $shipSymbol');
        return null;
      }
      search.markUsed(closest);
      final score = search.scoreFor(closest.systemSymbol);
      final systemJumpGate =
          systemsCache.jumpGateWaypointForSystem(closest.systemSymbol)!;
      final deal = await findNextDeal(
        agentCache,
        contractCache,
        marketPrices,
        systemsCache,
        routePlanner,
        ship,
        overrideStartSymbol: systemJumpGate.waypointSymbol,
        maxJumps: maxJumps,
        maxTotalOutlay: agentCache.agent.credits,
        maxWaypoints: maxWaypoints,
      );
      if (deal == null) {
        shipDetail(ship, 'No deal found for $shipSymbol at ${closest.symbol}');
        search.markUsed(closest);
        continue;
      }
      final profitPerSecond = deal.expectedProfitPerSecond;
      if (profitPerSecond < profitPerSecondThreshold) {
        shipDetail(
            ship,
            'Profit per second too low for $shipSymbol at '
            '${closest.symbol}, $profitPerSecond < $profitPerSecondThreshold');
        search.markUsed(closest);
        continue;
      }
      final placement = _ShipPlacement(
        score: score,
        distance: shipSystem.distanceTo(closest),
        profitPerSecond: profitPerSecond,
        destinationSymbol: systemJumpGate.waypointSymbol,
      );
      shipInfo(
          ship,
          'Found placement: ${creditsString(profitPerSecond)}/s '
          '${placement.score} ${placement.distance} '
          '${placement.destinationSymbol}');
      shipInfo(ship, 'Potential: ${describeCostedDeal(deal)}');
      return placement;
    }
  }

  /// Returns other systems containing ships with [behavior].
  Iterable<SystemSymbol> _otherSystemsWithBehavior(
    ShipSymbol thisShipSymbol,
    Behavior behavior,
  ) sync* {
    for (final state in _behaviorCache.states) {
      if (state.shipSymbol == thisShipSymbol) {
        continue;
      }
      if (state.behavior != behavior) {
        continue;
      }
      final destination = state.routePlan?.endSymbol;
      if (destination != null) {
        yield destination.systemSymbol;
      } else {
        final ship = _shipCache.ship(state.shipSymbol);
        yield ship.systemSymbol;
      }
    }
  }

  /// Returns all systems containing explorers or explorer destinations.
  Iterable<SystemSymbol> otherExplorerSystems(ShipSymbol thisShipSymbol) =>
      _otherSystemsWithBehavior(thisShipSymbol, Behavior.explorer);

  /// Returns all systems containing traders or trader destinations.
  Iterable<SystemSymbol> _otherTraderSystems(ShipSymbol thisShipSymbol) =>
      _otherSystemsWithBehavior(thisShipSymbol, Behavior.trader);

// This is a hack for now, we need real planning.
  /// Determine what type of ship to buy.
  // TODO(eseidel): This should consider pricing in it so that we can by
  // other ship types if they're not overpriced?
  ShipType? shipTypeToBuy(
    Ship ship,
    ShipyardPrices shipyardPrices,
    AgentCache agentCache,
    WaypointSymbol shipyardSymbol,
  ) {
    // We should buy a new ship when:
    // - We have request capacity to spare
    // - We have money to spare.
    // - We don't have better uses for the money (e.g. trading or modules)

    bool shipyardHas(ShipType shipType) {
      return shipyardPrices.recentPurchasePrice(
            shipyardSymbol: shipyardSymbol,
            shipType: shipType,
          ) !=
          null;
    }

    // Buy ships based on earnings of that ship type over the last N hours?
    final systemSymbol = ship.systemSymbol;
    final hqSystemSymbol = agentCache.headquartersSymbol.systemSymbol;
    final inStartSystem = systemSymbol == hqSystemSymbol;

    // Early game should be:
    // ~10 miners
    // 10 probes
    // No haulers until we have 100+ markets?
    // At some point start buying heavy freighters intead of light haulers?

    final shipCount = _shipCache.ships.length;
    final probeCount = _shipCache.countOfType(ShipType.PROBE);
    final houndCount = _shipCache.countOfType(ShipType.ORE_HOUND);

    // Early game can stop when we have enough miners going and markets
    // mapped to start trading.
    // This is not enough:
    // Loaded 364 prices from 61 markets and 7 prices from 2 shipyards.
    // Probably need a couple hundred markets.

    // We will buy miners in the start system.
    // Or probes anywhere (once we have enough miners).
    if (houndCount < 10 && inStartSystem) {
      if (shipCount < 4) {
        return ShipType.MINING_DRONE;
      }
      return ShipType.ORE_HOUND;
    } else if (houndCount > 5 && probeCount < 10) {
      return ShipType.PROBE;
    }
    // We will not buy traders until we have enough miners to support a base
    // income and enough probes to have found deals for us to trade.
    final isEarlyGame = _shipCache.ships.length < 20;
    if (isEarlyGame) {
      return null;
    }

    // const probeMinimum = 5;
    // final traderCount = _countOfTypeInFleet(ShipType.LIGHT_HAULER);
    // final probeTarget = min(traderCount / 2, probeMinimum);

    // SafPlusPlus limits to 50 probes and 40 miners
    final targetCounts = {
      ShipType.MINING_DRONE: 1,
      ShipType.ORE_HOUND: 40,
      ShipType.PROBE: 40,
      ShipType.LIGHT_HAULER: 20,
      ShipType.HEAVY_FREIGHTER: 40,
    };
    final typesToBuy = targetCounts.keys.where((shipType) {
      if (!shipyardHas(shipType)) {
        logger.info("Shipyard doesn't have $shipType");
        return false;
      }
      return _shipCache.countOfType(shipType) < targetCounts[shipType]!;
    }).toList();
    logger.info('typesToBuy: $typesToBuy');
    if (typesToBuy.isEmpty) {
      return null;
    }

    // We should buy haulers if we have fewer than X haulers idle and we have
    // enough extra cash on hand to support trading.
    if (typesToBuy.contains(ShipType.LIGHT_HAULER)) {
      final idleHaulers = idleHaulerSymbols(_shipCache, _behaviorCache);
      logger.info('Idle haulers: ${idleHaulers.length}');
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
    if (typesToBuy.contains(ShipType.HEAVY_FREIGHTER)) {
      return ShipType.HEAVY_FREIGHTER;
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
    final shipyardSymbol = ship.waypointSymbol;
    final shipType = shipTypeToBuy(
      ship,
      shipyardPrices,
      agentCache,
      shipyardSymbol,
    );
    // TODO(eseidel): This is wrong, this will disable buying for all
    // ships even though we might just be at a system where we don't need a ship
    // or can't afford one?
    if (shipType == null) {
      disableBehaviorForAll(
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
      disableBehaviorForAll(
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
      disableBehaviorForAll(
        ship,
        Behavior.buyShip,
        'Can not buy $shipType, budget $credits < max price $maxPrice.',
        const Duration(minutes: 10),
      );
      return false;
    }

    final recentPrice = shipyardPrices.recentPurchasePrice(
      shipyardSymbol: shipyardSymbol,
      shipType: shipType,
    );
    if (recentPrice == null) {
      disableBehaviorForShip(
        ship,
        Behavior.buyShip,
        'Shipyard at $shipyardSymbol does not sell $shipType.',
        const Duration(minutes: 10),
      );
      return false;
    }

    final recentPriceString = creditsString(recentPrice);
    if (recentPrice > maxPrice) {
      disableBehaviorForShip(
        ship,
        Behavior.buyShip,
        'Failed to buy $shipType at $shipyardSymbol, '
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
      shipyardSymbol,
      shipType,
    );

    disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Purchased ${result.ship.symbol} ($shipType)!',
      const Duration(minutes: 10),
    );
    return true;
  }

  /// Computes the number of units needed to fulfill the given [contract].
  /// Includes units in flight.
  @visibleForTesting
  int remainingUnitsNeededForContract(
    Contract contract,
    TradeSymbol tradeSymbol,
  ) {
    var unitsAssigned = 0;
    for (final shipSymbol in _shipCache.shipSymbols) {
      final deal = _behaviorCache.getBehavior(shipSymbol)?.deal;
      if (deal == null) {
        continue;
      }
      if (deal.contractId != contract.id) {
        continue;
      }
      unitsAssigned += deal.maxUnitsToBuy;
    }
    final neededGood = contract.goodNeeded(tradeSymbol);
    return neededGood!.unitsRequired -
        neededGood.unitsFulfilled -
        unitsAssigned;
  }

  /// Returns the minimum number of surveys to examine before mining
  int get minimumSurveys {
    // In the early game its more important to mine than get the perfect survey.
    // if (_shipCache.ships.length < 5) {
    //   return 2;
    // }
    return 10;
  }

  /// Returns the percentile of surveys to discard.
  double get surveyPercentileThreshold {
    // In the early game its more important to mine than get the perfect survey.
    // if (_shipCache.ships.length < 5) {
    //   return 0.5;
    // }
    return 0.9;
  }

  /// Returns the symbol of the nearest mine to the given [ship].
  // This should probably return a "mining plan" instead, which includes
  // what type of mining this is, where the mine is, where the markets are?
  WaypointSymbol? mineSymbolForShip(
    SystemsCache systemsCache,
    AgentCache agentCache,
    Ship ship,
  ) {
    final hq = agentCache.agent.headquartersSymbol;
    final hqSystemSymbol = hq.systemSymbol;
    final systemSymbol = hqSystemSymbol;
    // final systemSymbol = ship.systemSymbol;
    // Return the nearest mine to the ship for now?
    final systemWaypoints = systemsCache.waypointsInSystem(systemSymbol);
    return systemWaypoints
        .firstWhereOrNull((w) => w.canBeMined)
        ?.waypointSymbol;
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
    //     '$maxJumps radius of ${ship.systemSymbol}.',
    //     const Duration(hours: 1),
    //   );
    //   return null;
    // }
  }

  /// Find a better destination for the given trader [ship].
  Future<WaypointSymbol?> findBetterTradeLocation(
    SystemsCache systemsCache,
    RoutePlanner routePlanner,
    AgentCache agentCache,
    ContractCache contractCache,
    MarketPrices marketPrices,
    Ship ship, {
    required int maxJumps,
    required int maxWaypoints,
  }) async {
    final traderSystems = _otherTraderSystems(ship.shipSymbol).toList();
    final search = _MarketSearch.start(
      marketPrices,
      systemsCache,
      avoidSystems: traderSystems.toSet(),
    );
    final placement = await _findBetterSystemForTrader(
      systemsCache,
      routePlanner,
      agentCache,
      contractCache,
      marketPrices,
      search,
      ship,
      maxJumps: maxJumps,
      maxWaypoints: maxWaypoints,
      profitPerSecondThreshold: minTraderProfitPerSecond(ship),
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
Map<SystemSymbol, int> scoreMarketSystems(
  MarketPrices marketPrices, {
  int limit = 200,
}) {
  // Walk all markets in the market prices.  Get all goods for each market
  // compute the absolute distance for each good from the median price
  // sum up that value for the market and record that as the "market score".

  // First calculate median prices for all goods.
  final medianPurchasePrices = <TradeSymbol, int?>{};
  final medianSellPrices = <TradeSymbol, int?>{};
  for (final tradeSymbol in TradeSymbol.values) {
    medianPurchasePrices[tradeSymbol] =
        marketPrices.medianPurchasePrice(tradeSymbol);
    medianSellPrices[tradeSymbol] = marketPrices.medianSellPrice(tradeSymbol);
  }

  final marketSystemScores = <SystemSymbol, int>{};
  for (final price in marketPrices.prices) {
    final market = price.waypointSymbol;
    final system = market.systemSymbol;
    final medianPurchasePrice = medianPurchasePrices[price.tradeSymbol]!;
    final medianSellPrice = medianSellPrices[price.tradeSymbol]!;
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
List<ShipSymbol> idleHaulerSymbols(
  ShipCache shipCache,
  BehaviorCache behaviorCache,
) {
  final haulerSymbols =
      shipCache.ships.where((s) => s.isHauler).map((s) => s.shipSymbol);
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
  final WaypointSymbol destinationSymbol;
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
    Set<SystemSymbol>? avoidSystems,
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
  final Map<SystemSymbol, int> marketSystemScores;
  final Set<SystemSymbol> claimedSystemSymbols;

  System? closestAvailableSystem(
    SystemsCache systemsCache,
    System startSystem,
  ) {
    final availableSystems = marketSystems
        .where((system) => !claimedSystemSymbols.contains(system.systemSymbol))
        .toList();
    return _closestSystem(systemsCache, startSystem, availableSystems);
  }

  void markUsed(System system) => claimedSystemSymbols.add(system.systemSymbol);

  int scoreFor(SystemSymbol systemSymbol) => marketSystemScores[systemSymbol]!;
}
