import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

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

/// Where are we in the phases of the reset.
enum GamePhase with EnumIndexOrdering<GamePhase> {
  /// Early, we have little money, lots of request space.
  /// What matters most at this point is that we buy ships as fast as we can.
  /// We don't care a ton about price, more about opportunity cost (so we can
  /// spend our requests faster).
  /// Command center is trading when it can, but only near the starting system?
  /// The starting probe is parked at the starting shipyard or at least knows
  /// how to be back in time to buy things.
  /// We transition to Ramp when we can buy 1 module every 10 minutes?
  early,

  /// Ramp, we have money flowing in, but we haven't upgraded our ships yet.
  /// Our fleet is not yet full either.  We're buying modules when we can fit
  /// them (they're cheaper) and ships when we need more module space.
  /// We're trying to get to max efficiency as fast as possible.
  /// We transition to mid when we're at the request limit.
  ramp,

  /// We're at the request limit at this point. We're trying to maximize
  /// for profit per second.  Still mostly mining.  We're exploring so we can
  /// prepare for trading.
  /// We transition to trading transition when we turn off our first miner
  /// in favor of a trader?
  exploring,

  /// We're at the request limit.  We're trying to maximize profit per request
  /// Slowly converting from a mining based economy to a trading one.
  /// We transition to "end" when we have less than 4 hours until the end of
  /// the game.
  tradingTransition,

  /// The game has a fixed time limit and all actions should be optimized
  /// to maximize total credits at the end of that time.
  /// We don't want to start new long contracts at this point (or long trades)?
  /// Sell all mounts?
  end;
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

  /// Returns true if contract trading is enabled.
  /// We will only accept and start new contracts when this is true.
  /// We will continue to deliver current contract deals even if this is false,
  /// but will not start new deals involving contracts.
  bool get isContractTradingEnabled => true;

  /// What phase of the game we think we're in.
  GamePhase get phase {
    if (_shipCache.ships.length < 30) {
      return GamePhase.early;
    }
    // final traderCount = _shipCache.ships
    //     .where((s) => s.registration.role == ShipRole.HAULER)
    //     .length;
    // if (traderCount < 30) {
    //   return GamePhase.ramp;
    // }
    // // When is GamePhase.exploring?
    // return GamePhase.tradingTransition;
    return GamePhase.ramp;
  }

  /// Minimum profit per second we expect this ship to make.
  // Should set this based on the ship type and how much we expect to earn
  // from other sources (e.g. hauling mining goods?)
  int expectedCreditsPerSecond(Ship ship) {
    // Command makes a bit less than either miners or haulers due to its
    // worse cargo capacity and laser.
    if (ship.registration.role == ShipRole.COMMAND) {
      // We want to strongly prefer surveying for the mining drones early.
      // We increase their value by ~3c/s each, so 9c/s total?
      // But drones only get 5c/s anyway, so maybe not worth it?
      if (phase == GamePhase.early) {
        return 9;
      }
      // After we stop being a useful surveyor (once we have ore hounds)
      // We're not a great trader, but we'll take trades I guess?
      return 6;
    }
    // This should depend on phase and ship type?
    return 7;
  }

  /// Data older than this will be refreshed by explorers.
  /// Explorers will shorten this time if they run out of places to explore.
  Duration get maxAgeForExplorerData => _maxAgeForExplorerData;

  /// Shorten the max age for explorer data.
  Duration shortenMaxAgeForExplorerData() => _maxAgeForExplorerData ~/= 2;

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
    final genericMiner = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.MINER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.SURVEYOR_I,
      ]),
    );

    // According to SAF: Surveyor = 2x mk2s,  miner = 2x mk2 + 1x mk1
    final surveyOnly = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.MINER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.SURVEYOR_II,
        ShipMountSymbolEnum.SURVEYOR_II,
      ]),
    );
    // final mineOnly = ShipTemplate(
    //   frameSymbol: ShipFrameSymbolEnum.MINER,
    //   mounts: MountSymbolSet.from([
    //     ShipMountSymbolEnum.MINING_LASER_II,
    //     ShipMountSymbolEnum.MINING_LASER_II,
    //     ShipMountSymbolEnum.MINING_LASER_I,
    //   ]),
    // );

    // Hack to test a new template.
    final minerCount = _shipCache.countOfType(ShipType.ORE_HOUND);
    final surveyors = [
      'ESEIDEL-5',
      'ESEIDEL-6',
      'ESEIDEL-7',
    ];
    if (minerCount > 20 && surveyors.contains(ship.symbol)) {
      return surveyOnly;
    }

    final genericTemplates = [genericMiner];
    return genericTemplates
        .firstWhereOrNull((e) => e.frameSymbol == ship.frame.symbol);
  }

  /// Add up all mounts needed for current ships based on current templating.
  MountSymbolSet mountsNeededForAllShips() {
    final totalNeeded = MountSymbolSet();
    for (final ship in _shipCache.ships) {
      final template = templateForShip(ship);
      if (template == null) {
        continue;
      }
      totalNeeded.addAll(mountsToAddToShip(ship, template));
    }
    return totalNeeded;
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

    // Disable drones after ramping to a full fleet.
    if (phase > GamePhase.ramp) {
      if (ship.frame.symbol == ShipFrameSymbolEnum.DRONE) {
        return Behavior.idle;
      }
    }
    if (phase >= GamePhase.tradingTransition) {
      if (ship.frame.symbol == ShipFrameSymbolEnum.MINER) {
        return Behavior.idle;
      }
    }

    final shipCount = _shipCache.ships.length;

    final behaviors = {
      // TODO(eseidel): Evaluate based on expected value, not just order.
      // Should mine until we have one ore-hound, then switch to survey-only?

      ShipRole.COMMAND: [
        // We should deliver first, but deliver can get stuck, so we'll
        // try to buy a ship first.
        Behavior.buyShip,
        // If we can get mounts for our ships, that's the best thing we can do.
        Behavior.deliver,
        // Will only trade if we can make 6/s or more.
        // There are commonly 20c/s trades in the starting system, and at
        // the minimum we want to accept the contract.
        // Might want to consider limiting to short trades (< 5 mins) to avoid
        // tying up capital early.
        Behavior.trader,
        // Early on the command ship makes about 5c/s vs. ore hounds making
        // 6c/s. It's a better surveyor than miner. Especially when enabling
        // mining drones.
        if (shipCount > 3 && shipCount < 10) Behavior.surveyor,
        Behavior.miner,
      ],
      // Haulers are terrible explorers, but early game we just need
      // things mapping.
      ShipRole.HAULER: [
        Behavior.trader,
        Behavior.explorer,
      ],
      ShipRole.EXCAVATOR: [
        // We'll always upgrade the ship as our best option.
        Behavior.changeMounts,
        if (phase < GamePhase.tradingTransition && ship.canMine) Behavior.miner,
        if (phase < GamePhase.tradingTransition &&
            !ship.canMine &&
            ship.hasSurveyor)
          Behavior.surveyor,
        Behavior.idle,
      ],
      ShipRole.SATELLITE: [Behavior.explorer],
    }[ship.registration.role];
    if (behaviors != null) {
      for (final behavior in behaviors) {
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

  /// Disable the given behavior for [ship] for [duration].
  void disableBehaviorForShip(
    Ship ship,
    String why,
    Duration duration, {
    Behavior? explicitBehavior,
  }) {
    final shipSymbol = ship.shipSymbol;
    final currentState = _behaviorCache.getBehavior(shipSymbol);
    final behavior = explicitBehavior ?? currentState?.behavior;
    if (behavior == null) {
      shipWarn(ship, '$shipSymbol has no behavior to disable.');
      return;
    }
    shipWarn(
      ship,
      '$why Disabling $behavior for $shipSymbol '
      'for ${approximateDuration(duration)}.',
    );

    if (currentState == null || currentState.behavior == behavior) {
      _behaviorCache.deleteBehavior(shipSymbol);
    } else {
      shipInfo(ship, 'Not deleting ${currentState.behavior} for $shipSymbol.');
    }

    final expiration = DateTime.timestamp().add(duration);
    _shipTimeouts.add(_ShipTimeout(ship.shipSymbol, behavior, expiration));
  }

  /// Returns the delivery ship bringing the mounts.
  Ship? getDeliveryShip(ShipSymbol shipSymbol, TradeSymbol item) {
    final deliveryShip = _shipCache.ships.first;
    final deliveryState = _behaviorCache.getBehavior(deliveryShip.shipSymbol);
    if (deliveryState?.behavior != Behavior.deliver) {
      return null;
    }
    // Check if it's at the shipyard?
    return deliveryShip;
  }

  /// Returns the counts of mounts already claimed.
  MountSymbolSet claimedMounts() {
    final claimed = MountSymbolSet();
    for (final state in _behaviorCache.states) {
      final behavior = state.behavior;
      if (behavior != Behavior.changeMounts) {
        continue;
      }
      final mountSymbol = state.mountToAdd;
      if (mountSymbol == null) {
        continue;
      }
      claimed.add(mountSymbol);
    }
    return claimed;
  }

  /// Returns the number of mounts available at the waypoint.
  MountSymbolSet unclaimedMountsAt(WaypointSymbol waypoint) {
    // Get all the ships at that symbol
    final ships = _shipCache.ships
        .where((s) => s.waypointSymbol == waypoint && !s.isInTransit);

    // That have behavior delivery.
    final available = MountSymbolSet();
    for (final ship in ships) {
      final state = _behaviorCache.getBehavior(ship.shipSymbol);
      if (state == null || state.behavior != Behavior.deliver) {
        continue;
      }
      available.addAll(ship.mountSymbolsInInventory);
    }
    final claimed = claimedMounts();
    // Unclear where this warning belongs.
    for (final symbol in claimed.distinct) {
      if (claimed[symbol] > available[symbol]) {
        logger.warn(
          'More mounts claimed than available at $waypoint: '
          '${claimed[symbol]} > ${available[symbol]}',
        );
      }
    }
    return available.difference(claimed);
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

  /// Returns all deals in progress.
  Iterable<CostedDeal> _dealsInProgress() sync* {
    for (final state in _behaviorCache.states) {
      final deal = state.deal;
      if (deal != null) {
        yield deal;
      }
    }
  }

  /// Procurement contracts converted to sell opps.
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
          yield SellOpp.fromContract(
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
  CostedDeal? findNextDeal(
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
  }) {
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
    final maybeDeal = findDealFor(
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

  _ShipPlacement? _findBetterSystemForTrader(
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
  }) {
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
      final deal = findNextDeal(
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
    // Buy ships based on earnings of that ship type over the last N hours?
    final systemSymbol = ship.systemSymbol;
    final hqSystemSymbol = agentCache.headquartersSymbol.systemSymbol;
    final inStartSystem = systemSymbol == hqSystemSymbol;

    final houndCount = _shipCache.countOfType(ShipType.ORE_HOUND);
    if (houndCount < 80) {
      if (inStartSystem) {
        return ShipType.ORE_HOUND;
      } else {
        return null;
      }
    } else if (_shipCache.countOfType(ShipType.HEAVY_FREIGHTER) < 10) {
      return ShipType.HEAVY_FREIGHTER;
    } else {
      return null;
    }
  }

  // TODO(eseidel): Move out commandCenter.  Will require fixing unit tests.
  /// Visits the local shipyard if we're at a waypoint with a shipyard.
  /// Records shipyard data if needed.
  Future<void> visitLocalShipyard(
    Api api,
    Database db,
    ShipyardPrices shipyardPrices,
    AgentCache agentCache,
    Waypoint waypoint,
    Ship ship,
  ) async {
    if (!waypoint.hasShipyard) {
      return;
    }
    final shipyard = await getShipyard(api, waypoint);
    recordShipyardDataAndLog(shipyardPrices, shipyard, ship);
  }

  /// What the max multiplier of median we would pay for a ship.
  double get maxMedianShipPriceMultipler => 1.1;

  /// How many haulers do we have?
  int get numberOfHaulers =>
      _shipCache.frameCounts[ShipFrameSymbolEnum.LIGHT_FREIGHTER] ?? 0;

  /// The minimum credits we should have to buy a new ship.
  int get minimumCreditsForTrading => numberOfHaulers * 10000;

  /// Attempt to buy a ship for the given [ship].
  // TODO(eseidel): Unify this with buyShip behavior.
  Future<bool> buyShipIfPossible(
    Api api,
    Database db,
    ShipyardPrices shipyardPrices,
    AgentCache agentCache,
    Ship ship,
  ) async {
    if (isBehaviorDisabled(Behavior.buyShip) ||
        isBehaviorDisabledForShip(ship, Behavior.buyShip)) {
      return false;
    }

    // This assumes the ship in question is at a shipyard and already docked.
    final shipyardSymbol = ship.waypointSymbol;
    // This only works if we've recorded prices from this shipyard before.
    final knownPrices = shipyardPrices.pricesAtShipyard(ship.waypointSymbol);
    final availableTypes = knownPrices.map((p) => p.shipType);
    shipInfo(
      ship,
      'Visiting shipyard $shipyardSymbol, available: $availableTypes',
    );

    final shipType = assertNotNull(
      shipTypeToBuy(
        ship,
        shipyardPrices,
        agentCache,
        shipyardSymbol,
      ),
      'No ship to buy at $shipyardSymbol.',
      const Duration(minutes: 5),
    );

    final result = await doBuyShipJob(
      api,
      db,
      _shipCache,
      shipyardPrices,
      agentCache,
      ship,
      ShipBuyJob(shipType, shipyardSymbol),
      maxMedianShipPriceMultipler: maxMedianShipPriceMultipler,
      minimumCreditsForTrading: minimumCreditsForTrading,
    );

    // Abusing jobAssert a little here to throw an exception on success
    // which will clear only the buyShip behavior.
    jobAssert(
      false,
      'Purchased ${result.ship.symbol} ($shipType)!',
      const Duration(minutes: 5),
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

  /// Returns the mining plan for the given [ship].
  MineJob mineJobForShip(
    SystemsCache systemsCache,
    AgentCache agentCache,
    Ship ship,
  ) {
    final hq = agentCache.agent.headquartersSymbol;
    final hqSystemSymbol = hq.systemSymbol;
    final systemSymbol = hqSystemSymbol;
    final systemWaypoints = systemsCache.waypointsInSystem(systemSymbol);
    final mine = systemWaypoints.firstWhere((w) => w.canBeMined).waypointSymbol;
    return MineJob(mine: mine, market: mine);
    // If the ship is in a system without a mine go to the HQ?
  }

  /// Find a better destination for the given trader [ship].
  WaypointSymbol? findBetterTradeLocation(
    SystemsCache systemsCache,
    RoutePlanner routePlanner,
    AgentCache agentCache,
    ContractCache contractCache,
    MarketPrices marketPrices,
    Ship ship, {
    required int maxJumps,
    required int maxWaypoints,
  }) {
    final traderSystems = _otherTraderSystems(ship.shipSymbol).toList();
    final search = _MarketSearch.start(
      marketPrices,
      systemsCache,
      avoidSystems: traderSystems.toSet(),
    );
    final placement = _findBetterSystemForTrader(
      systemsCache,
      routePlanner,
      agentCache,
      contractCache,
      marketPrices,
      search,
      ship,
      maxJumps: maxJumps,
      maxWaypoints: maxWaypoints,
      profitPerSecondThreshold: expectedCreditsPerSecond(ship),
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
