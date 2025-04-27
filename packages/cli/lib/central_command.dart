import 'dart:math';

import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/charter.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/behavior/system_watcher.dart';
import 'package:cli/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/plan/extraction_score.dart';
import 'package:cli/plan/mining.dart';
import 'package:cli/plan/supply_chain.dart';
import 'package:cli/plan/trading.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:meta/meta.dart';
import 'package:types/prediction.dart';
import 'package:types/types.dart';

// This is a bit of a cheat.  It appears starter systems all have over 20
// non-asteroid waypoints.  We can use this to find starter systems.
/// Returns the set of systems we should prefer to chart.
Set<SystemSymbol> findInterestingSystems(SystemsCache systemsCache) {
  final allSystems = systemsCache.systems;
  // All systems with over 20 non-asteroid waypoints:
  return allSystems
      .where(
        (system) => system.waypoints.where((w) => !w.isAsteroid).length > 20,
      )
      .map((system) => system.symbol)
      .toSet();
}

/// Central command for the fleet.
class CentralCommand {
  /// Create a new central command.
  CentralCommand({BehaviorTimeouts? behaviorTimeouts})
    : behaviorTimeouts = behaviorTimeouts ?? BehaviorTimeouts();

  bool _isGateComplete = false;

  DateTime? _lastRoutingCacheUpdate;

  /// Per-system price age data used by system watchers.
  final Map<SystemSymbol, Duration> _maxPriceAgeForSystem = {};
  final Map<SystemSymbol, bool> _chartAsteroidsInSystem = {};

  /// The next planned ship buy job.
  /// This is the start of an imagined job queue system, whereby we pre-populate
  /// BehaviorStates with jobs when handing them out to ships.
  ShipBuyJob? _nextShipBuyJob;

  /// The current construction job.
  // Visible so that nearby_deals script can set it.
  Construction? activeConstruction;

  /// The current market subsidies.  Used for motivating construction markets.
  // Visible so that nearby_deals script can set it.
  List<SellOpp> subsidizedSellOpps = [];

  /// The current mining squads.
  List<ExtractionSquad> miningSquads = [];

  /// Mounts we know of a place we can buy.
  final Set<ShipMountSymbolEnum> _availableMounts = {};

  final Map<ShipSymbol, SystemSymbol> _assignedSystemsForSatellites = {};

  /// The current behavior timeouts.
  final BehaviorTimeouts behaviorTimeouts;

  /// median purchase price for fuel.
  int medianFuelPurchasePrice = config.defaultFuelCost;

  /// median purchase price for antimatter.
  int medianAntimatterPurchasePrice = config.defaultAntimatterCost;

  /// Sets the available mounts for testing.
  @visibleForTesting
  void setAvailableMounts(Iterable<ShipMountSymbolEnum> mounts) {
    _availableMounts
      ..clear()
      ..addAll(mounts);
  }

  /// The planned mount buy jobs for any ships that need them.
  final List<MountRequest> _mountRequests = [];

  /// Returns true if contract trading is enabled.
  /// We will only accept and start new contracts when this is true.
  /// We will continue to deliver current contract deals even if this is false,
  /// but will not start new deals involving contracts.
  /// Mostly this makes unit-testing easier by allowing us to disable contract
  /// trading.
  bool get isContractTradingEnabled => config.enableContracts;

  /// Returns true if construction trading is enabled.
  bool get isConstructionTradingEnabled => config.enableConstruction;

  /// Minimum profit per second we expect this ship to make.
  // Should set this based on the ship type and how much we expect to earn
  // from other sources (e.g. hauling mining goods?)
  int expectedCreditsPerSecond(Ship ship) {
    // If we're stuck in our own system, any trades are better than exploring.
    // This doesn't include the command ship, which may be an error.
    if (!_isGateComplete && ship.fleetRole == FleetRole.trader) {
      return 1;
    }
    // This should depend on phase and ship type?
    return 4;
  }

  /// Returns the max age for price data for the given [systemSymbol].
  Duration maxPriceAgeForSystem(SystemSymbol systemSymbol) {
    final maybeAge = _maxPriceAgeForSystem[systemSymbol];
    if (maybeAge != null) {
      return maybeAge;
    }
    return config.defaultMaxAgeForPriceData;
  }

  /// Shorten the max age for price data for the given [systemSymbol].
  Duration shortenMaxPriceAgeForSystem(SystemSymbol systemSymbol) {
    final age = maxPriceAgeForSystem(systemSymbol);
    return _maxPriceAgeForSystem[systemSymbol] = age ~/ 2;
  }

  /// Returns true if we should chart asteroids in the given [systemSymbol].
  bool chartAsteroidsInSystem(SystemSymbol systemSymbol) {
    return _chartAsteroidsInSystem[systemSymbol] ??
        config.chartAsteroidsByDefault;
  }

  /// Sets whether we should chart asteroids in the given [systemSymbol].
  void setChartAsteroidsInSystem(SystemSymbol systemSymbol) {
    _chartAsteroidsInSystem[systemSymbol] = true;
  }

  /// Returns the system symbol we should assign the given [ship] to.
  SystemSymbol? assignedSystemForSatellite(Ship ship) =>
      _assignedSystemsForSatellites[ship.symbol];

  /// Returns the mining squad for the given [ship].
  ExtractionSquad? squadForShip(Ship ship) {
    final squad = miningSquads.firstWhereOrNull((s) => s.contains(ship));
    if (squad == null) {
      return null;
    }
    return squad;
  }

  /// What template should we use for the given ship?
  ShipTemplate? templateForShip(Ship ship) {
    final squad = squadForShip(ship);
    if (squad == null) {
      return null;
    }
    return squad.templateForShip(ship, availableMounts: _availableMounts);
  }

  /// Add up all mounts needed for current ships based on current templating.
  MountSymbolSet mountsNeededForAllShips(ShipSnapshot ships) {
    final totalNeeded = MountSymbolSet();
    for (final ship in ships.ships) {
      final template = templateForShip(ship);
      if (template == null) {
        continue;
      }
      totalNeeded.addAll(mountsToAddToShip(ship, template));
    }
    return totalNeeded;
  }

  /// Returns an initialized behavior state for the given [ship] to start
  /// its next job.
  Future<BehaviorState> getJobForShip(
    Database db,
    SystemConnectivity systemConnectivity,
    Ship ship,
    int credits,
  ) async {
    final shipSymbol = ship.symbol;
    BehaviorState toState(Behavior behavior) {
      return BehaviorState(shipSymbol, behavior);
    }

    if (config.gamePhase == GamePhase.selloff) {
      return toState(Behavior.scrap);
    }

    bool enabled(Behavior behavior) {
      if (!config.enableMining && config.miningBehaviors.contains(behavior)) {
        return false;
      }

      return !behaviorTimeouts.isBehaviorDisabledForShip(ship, behavior);
    }

    if (ship.isOutOfFuel) {
      return toState(Behavior.idle);
    }
    // We'll always upgrade a ship as our best option.
    if (enabled(Behavior.mountFromBuy) &&
        await shouldBuyMount(db, ship, credits)) {
      final request = _takeMountRequest(ship);
      shipInfo(ship, 'Starting buy mount ${request.mountSymbol}');
      return BehaviorState(
        shipSymbol,
        Behavior.mountFromBuy,
        buyJob: request.buyJob,
        mountJob: request.mountJob,
      );
    }
    // Otherwise buy a ship if we can.
    if (enabled(Behavior.buyShip) &&
        await shouldBuyShip(db, systemConnectivity, ship, credits)) {
      return BehaviorState(
        shipSymbol,
        Behavior.buyShip,
        shipBuyJob: takeShipBuyJob(),
      );
    }

    final squad = squadForShip(ship);
    if (squad != null) {
      var behavior =
          {
            FleetRole.miner: Behavior.miner,
            FleetRole.surveyor: Behavior.surveyor,
            FleetRole.siphoner: Behavior.siphoner,
          }[ship.fleetRole];
      if (behavior == null && ship.isHauler && enabled(Behavior.minerHauler)) {
        behavior = Behavior.minerHauler;
      }
      if (behavior != null && enabled(behavior)) {
        return BehaviorState(shipSymbol, behavior, extractionJob: squad.job);
      }
    }

    if (ship.isProbe) {
      final assignedSystem = assignedSystemForSatellite(ship);
      if (assignedSystem != null && enabled(Behavior.systemWatcher)) {
        return BehaviorState(
          shipSymbol,
          Behavior.systemWatcher,
          systemWatcherJob: SystemWatcherJob(systemSymbol: assignedSystem),
        );
      }
      if (enabled(Behavior.charter)) {
        return toState(Behavior.charter);
      } else if (enabled(Behavior.systemWatcher)) {
        return BehaviorState(
          shipSymbol,
          Behavior.systemWatcher,
          systemWatcherJob: SystemWatcherJob(systemSymbol: ship.systemSymbol),
        );
      }
    }

    // Otherwise start any other job.
    final behaviors = config.behaviorsByFleetRole[ship.fleetRole];
    if (behaviors != null) {
      for (final behavior in behaviors) {
        if (!behaviorTimeouts.isBehaviorDisabledForShip(ship, behavior)) {
          return toState(behavior);
        }
      }
    } else {
      // Warn except in the common case of disabling miners.
      if (config.enableMining ||
          !config.miningFleetRoles.contains(ship.fleetRole)) {
        logger.warn('${ship.fleetRole} has no specified behaviors, idling.');
      }
    }
    return toState(Behavior.idle);
  }

  /// Procurement contracts converted to sell opps.
  Iterable<SellOpp> contractSellOpps(
    AgentCache agentCache,
    BehaviorSnapshot behaviors,
    ContractSnapshot contractSnapshot,
  ) {
    return sellOppsForContracts(
      agentCache,
      behaviors,
      contractSnapshot,
      remainingUnitsNeededForContract: remainingUnitsNeededForContract,
    );
  }

  /// SellOpps to complete the current construction job.
  Iterable<SellOpp> constructionSellOpps(BehaviorSnapshot behaviors) {
    if (activeConstruction == null) {
      return [];
    }
    return [
      ...sellOppsForConstruction(
        activeConstruction!,
        remainingUnitsNeeded: (tradeSymbol) {
          return remainingUnitsNeededForConstruction(
            behaviors,
            activeConstruction!,
            tradeSymbol,
          );
        },
      ),
      ...subsidizedSellOpps,
    ];
  }

  /// Find next deal for the given [ship], considering all deals in progress.
  CostedDeal? findNextDealAndLog(
    AgentCache agentCache,
    ContractSnapshot contractSnapshot,
    MarketPriceSnapshot marketPrices,
    SystemsCache systemsCache,
    SystemConnectivity systemConnectivity,
    RoutePlanner routePlanner,
    BehaviorSnapshot behaviors,
    Ship ship, {
    required int maxTotalOutlay,
    // overrideStartSymbol is used by findBetterTradeLocation to restrict
    // pretend that the ship is already at overrideStartSymbol, and show
    // only trades which start from within that system.
    WaypointSymbol? overrideStartSymbol,
  }) {
    final startSymbol = overrideStartSymbol ?? ship.waypointSymbol;
    final restrictToStartSystem = overrideStartSymbol?.system;

    final extraSellOpps = <SellOpp>[];
    if (isConstructionTradingEnabled) {
      extraSellOpps.addAll(constructionSellOpps(behaviors));
    }
    if (isContractTradingEnabled) {
      extraSellOpps.addAll(
        contractSellOpps(agentCache, behaviors, contractSnapshot),
      );
    }
    if (extraSellOpps.isNotEmpty) {
      final opp = extraSellOpps.first;
      logger.detail(
        'Including contract sell opp: ${opp.maxUnits} ${opp.tradeSymbol} '
        '@ ${creditsString(opp.price)} -> ${opp.waypointSymbol}',
      );
    }
    final costPerFuelUnit =
        marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ??
        config.defaultFuelCost;
    final costPerAntimatterUnit =
        marketPrices.medianPurchasePrice(TradeSymbol.ANTIMATTER) ??
        config.defaultAntimatterCost;

    final deals = scanAndFindDeals(
      systemsCache,
      systemConnectivity,
      marketPrices,
      routePlanner,
      maxTotalOutlay: maxTotalOutlay,
      startSymbol: startSymbol,
      extraSellOpps: extraSellOpps,
      shipSpec: ship.shipSpec,
      filter: avoidDealsInProgress(
        behaviors.dealsInProgress(),
        filter: (d) {
          return restrictToStartSystem == null ||
              d.sourceSymbol.system == restrictToStartSystem;
        },
      ),
      costPerAntimatterUnit: costPerAntimatterUnit,
      costPerFuelUnit: costPerFuelUnit,
    );

    // A hack to avoid spamming the console until we add a deals cache.
    if (deals.isNotEmpty) {
      logger.info(
        'Found ${deals.length} deals for ${ship.symbol} from '
        '$startSymbol',
      );
    }
    for (final deal in deals) {
      logger.detail(describeCostedDeal(deal));
    }
    return deals.firstOrNull;
  }

  /// Returns the next waypoint symbol to chart.
  Future<WaypointSymbol?> nextWaypointToChart(
    ShipSnapshot ships,
    BehaviorSnapshot behaviors,
    SystemsCache systems,
    ChartingSnapshot charts,
    SystemConnectivity connectivity,
    Ship ship, {
    required int maxJumps,
  }) async {
    final charterSystems =
        otherCharterSystems(ships, behaviors, ship.symbol).toSet();

    // Only probes should ever chart asteroids.
    final chartAsteroids =
        chartAsteroidsInSystem(ship.systemSymbol) && ship.isProbe;

    // Walk waypoints as far out as we can see until we find one missing
    // a chart or market data and route to there.
    final destinationSymbol = await nextUnchartedWaypointSymbol(
      systems,
      charts,
      connectivity,
      ship,
      // Start at the ship's current system to minimize jumps.
      startSystemSymbol: ship.systemSymbol,
      filter: (SystemWaypoint waypoint) {
        // Don't bother charting Asteroids if disabled.
        if (!chartAsteroids && waypoint.isAsteroid) {
          return false;
        }
        // Don't visit systems we already have a charter in.
        return !charterSystems.contains(waypoint.system);
      },
      maxJumps: maxJumps,
    );
    return destinationSymbol;
  }

  /// Returns other systems containing ships with [behavior].
  Iterable<SystemSymbol> _otherSystemsWithBehavior(
    ShipSnapshot ships,
    BehaviorSnapshot behaviors,
    ShipSymbol thisShipSymbol,
    Behavior behavior,
  ) {
    return _otherWaypointsWithBehavior(
      ships,
      behaviors,
      thisShipSymbol,
      behavior,
    ).map((s) => s.system);
  }

  /// Returns other systems containing ships with [behavior].
  Iterable<WaypointSymbol> _otherWaypointsWithBehavior(
    ShipSnapshot ships,
    BehaviorSnapshot behaviors,
    ShipSymbol thisShipSymbol,
    Behavior behavior,
  ) sync* {
    for (final state in behaviors.states) {
      if (state.shipSymbol == thisShipSymbol) {
        continue;
      }
      if (state.behavior != behavior) {
        continue;
      }
      // Yield both the ship's current waypoint and its destination.
      yield ships[state.shipSymbol]!.waypointSymbol;

      final destination = state.routePlan?.endSymbol;
      if (destination != null) {
        yield destination;
      }
    }
  }

  /// Returns all systems containing explorers or explorer destinations.
  Iterable<WaypointSymbol> waypointsToAvoidInSystem(
    ShipSnapshot ships,
    BehaviorSnapshot behaviors,
    SystemSymbol systemSymbol,
    ShipSymbol thisShipSymbol,
  ) => _otherWaypointsWithBehavior(
    ships,
    behaviors,
    thisShipSymbol,
    Behavior.systemWatcher,
  ).where((s) => s.system == systemSymbol);

  /// Returns all systems containing charters or charter destinations.
  Iterable<SystemSymbol> otherCharterSystems(
    ShipSnapshot ships,
    BehaviorSnapshot behaviors,
    ShipSymbol thisShipSymbol,
  ) => _otherSystemsWithBehavior(
    ships,
    behaviors,
    thisShipSymbol,
    Behavior.charter,
  );

  /// Returns all systems containing traders or trader destinations.
  Iterable<SystemSymbol> otherTraderSystems(
    ShipSnapshot ships,
    BehaviorSnapshot behaviors,
    ShipSymbol thisShipSymbol,
  ) => _otherSystemsWithBehavior(
    ships,
    behaviors,
    thisShipSymbol,
    Behavior.trader,
  );

  Future<void> _queueMountRequests(
    Database db,
    RoutePlanner routePlanner,
    ShipyardListingSnapshot shipyardListings,
    MarketPriceSnapshot marketPrices,
    ShipSnapshot ships,
  ) async {
    for (final ship in ships.ships) {
      if (_mountRequests.any((m) => m.shipSymbol == ship.symbol)) {
        return;
      }
      // Don't queue a new mount request if we're currently executing one.
      final behaviorState = await db.behaviorStateBySymbol(ship.symbol);
      if (behaviorState?.behavior == Behavior.mountFromBuy) {
        continue;
      }
      final template = templateForShip(ship);
      if (template == null) {
        continue;
      }
      final expectedCreditsPerSecond = this.expectedCreditsPerSecond(ship);
      final request = await mountRequestForShip(
        this,
        marketPrices,
        routePlanner,
        shipyardListings,
        ship,
        template,
        expectedCreditsPerSecond: expectedCreditsPerSecond,
      );
      if (request != null) {
        _mountRequests.add(request);
      }
    }
  }

  /// Updates _availableMounts with any mounts we know of a place to buy.
  Future<void> updateAvailableMounts(Database db) async {
    for (final mountSymbol in ShipMountSymbolEnum.values) {
      if (_availableMounts.contains(mountSymbol)) {
        continue;
      }
      final isAvailable = await db.knowOfMarketWhichTrades(
        tradeSymbolForMountSymbol(mountSymbol),
      );
      if (isAvailable) {
        _availableMounts.add(mountSymbol);
      }
    }
  }

  Future<ConstructionRecord?> _constructionForSystem(
    Database db,
    SystemsCache systems,
    SystemSymbol systemSymbol,
  ) async {
    final SystemWaypoint? jumpGate;
    try {
      jumpGate = systems.jumpGateWaypointForSystem(systemSymbol);
    } on Exception catch (e) {
      logger.warn('Failed to find jump gate for $systemSymbol: $e');
      return null;
    }
    if (jumpGate == null) {
      return null;
    }
    return await ConstructionCache(db).getRecord(jumpGate.symbol);
  }

  /// Returns true if the jumpgate for the given [systemSymbol] is complete.
  /// Returns null if we don't know.
  Future<bool?> isJumpgateComplete(
    Database db,
    SystemsCache systems,
    SystemSymbol systemSymbol,
  ) async {
    final record = await _constructionForSystem(db, systems, systemSymbol);
    if (record == null) {
      return null;
    }
    return !record.isUnderConstruction;
  }

  /// Returns the active construction job, if any.
  Future<Construction?> computeActiveConstruction(
    Database db,
    AgentCache agentCache,
    SystemsCache systems,
  ) async {
    if (!isConstructionTradingEnabled) {
      return null;
    }
    if (agentCache.agent.credits < config.constructionMinCredits) {
      return null;
    }

    final systemSymbol = agentCache.headquartersSystemSymbol;
    final record = await _constructionForSystem(db, systems, systemSymbol);
    return record?.construction;
  }

  Future<void> _updateMedianPrices(Database db) async {
    final medianFuelPrice = await db.medianMarketPurchasePrice(
      TradeSymbol.FUEL,
    );
    if (medianFuelPrice != null) {
      medianFuelPurchasePrice = medianFuelPrice;
    }
    final medianAntimatterPrice = await db.medianMarketPurchasePrice(
      TradeSymbol.ANTIMATTER,
    );
    if (medianAntimatterPrice != null) {
      medianAntimatterPurchasePrice = medianAntimatterPrice;
    }
  }

  /// Creates a new buy ship job if needed.
  Future<void> updateBuyShipJobIfNeeded(
    Database db,
    Api api,
    Caches caches,
    ShipyardListingSnapshot shipyardListings,
    ShipSnapshot ships,
  ) async {
    _nextShipBuyJob ??= await _computeNextShipBuyJob(
      db,
      api,
      caches,
      shipyardListings,
      ships,
    );
  }

  GamePhase _determineGamePhase(
    ShipSnapshot ships, {
    required bool jumpGateComplete,
  }) {
    // A hack to advance the global config to the construction phase.
    if (jumpGateComplete) {
      return GamePhase.exploration;
    } else if (ships.countOfFrame(ShipFrameSymbolEnum.LIGHT_FREIGHTER) >= 10) {
      return GamePhase.construction;
    }
    return GamePhase.bootstrap;
  }

  /// This is a terrible hack.  We should instead invalidate routing caches
  /// every time we add a jump gate.
  Future<void> _updateRoutingCachesIfNeeded(Caches caches) async {
    final now = DateTime.timestamp();
    final lastUpdate = _lastRoutingCacheUpdate;
    // If this is our first run, just set the last update time and return.
    if (lastUpdate == null) {
      _lastRoutingCacheUpdate = now;
      return;
    }
    if (now.difference(lastUpdate) > config.routingCacheMaxAge) {
      _lastRoutingCacheUpdate = now;
      return caches.updateRoutingCaches();
    }
    return Future.value();
  }

  /// Give central planning a chance to advance.
  /// Currently only run once every N loops (currently 50).
  Future<void> advanceCentralPlanning(
    Database db,
    Api api,
    Caches caches,
  ) async {
    // TODO(eseidel): Add proper routing cache invalidation and remove this.
    await _updateRoutingCachesIfNeeded(caches);

    final ships = await ShipSnapshot.load(db);
    _isGateComplete =
        await isJumpgateComplete(
          db,
          caches.systems,
          caches.agent.headquartersSystemSymbol,
        ) ??
        false;
    final phase = _determineGamePhase(ships, jumpGateComplete: _isGateComplete);
    logger.info('$phase');
    if (phase != config.gamePhase) {
      await db.setGamePhase(phase);
      config = await Config.fromDb(db);
    }

    final marketListings = await MarketListingSnapshot.load(db);
    final shipyardListings = await ShipyardListingSnapshot.load(db);
    final charting = await ChartingSnapshot.load(db);

    await _updateMedianPrices(db);

    _assignedSystemsForSatellites
      ..clear()
      ..addAll(
        assignProbesToSystems(caches.systemConnectivity, marketListings, ships),
      );

    if (config.enableMining) {
      miningSquads = await assignShipsToSquads(
        db,
        caches.systems,
        caches.charting,
        ships,
        systemSymbol: caches.agent.headquartersSystemSymbol,
      );
    } else {
      miningSquads = [];
    }

    await updateBuyShipJobIfNeeded(db, api, caches, shipyardListings, ships);

    // Mounts are currently only used for mining.
    if (config.enableMining) {
      await updateAvailableMounts(db);
      await _queueMountRequests(
        db,
        caches.routePlanner,
        shipyardListings,
        caches.marketPrices,
        ships,
      );
    }

    activeConstruction = await computeActiveConstruction(
      db,
      caches.agent,
      caches.systems,
    );
    subsidizedSellOpps = [];
    if (isConstructionTradingEnabled && activeConstruction != null) {
      subsidizedSellOpps = await computeConstructionMaterialSubsidies(
        db,
        caches.systems,
        await caches.static.exports.snapshot(),
        marketListings,
        charting,
        activeConstruction!,
      );
    }
  }

  /// Returns the next ship buy job.
  ShipBuyJob? get nextShipBuyJob => _nextShipBuyJob;

  @visibleForTesting
  set nextShipBuyJob(ShipBuyJob? job) => _nextShipBuyJob = job;

  /// Takes and clears the next ship buy job.
  ShipBuyJob? takeShipBuyJob() {
    final job = _nextShipBuyJob;
    _nextShipBuyJob = null;
    return job;
  }

  /// Takes and clears the next mount buy job for the given [ship].
  MountRequest _takeMountRequest(Ship ship) {
    final mountRequest = _mountRequests.firstWhere(
      (m) => m.shipSymbol == ship.symbol,
      orElse: () => throw ArgumentError('No mount request for $ship'),
    );
    _mountRequests.remove(mountRequest);
    return mountRequest;
  }

  Future<ShipBuyJob?> _findBestPlaceToBuy(
    Database db,
    RoutePlanner routePlanner,
    Ship ship,
    ShipType shipType,
  ) async {
    final shipyardPrices = await ShipyardPriceSnapshot.load(db);
    final trip = findBestShipyardToBuy(
      shipyardPrices,
      routePlanner,
      ship,
      shipType,
      expectedCreditsPerSecond: expectedCreditsPerSecond(ship),
    );
    if (trip == null) {
      return null;
    }
    final recentPrice = shipyardPrices.recentPurchasePrice(
      shipType: shipType,
      shipyardSymbol: trip.route.endSymbol,
    );
    // This should never happen if we found a trip.
    if (recentPrice == null) {
      return null;
    }
    return ShipBuyJob(
      shipType: shipType,
      shipyardSymbol: trip.route.endSymbol,
      minCreditsNeeded: (recentPrice * 1.05).toInt(),
    );
  }

  Future<ShipBuyJob?> _unreachableSystemProbe(
    Database db,
    Api api,
    AgentCache agentCache,
    SystemConnectivity systemConnectivity,
    ShipyardListingSnapshot shipyardListings,
    ShipSnapshot ships,
  ) async {
    // Get our main cluster id.
    final hqSystemSymbol = agentCache.headquartersSystemSymbol;
    // List all systems with explorers in them.
    final systemsWithExplorers =
        ships.ships
            .where((s) => s.fleetRole == FleetRole.explorer)
            .map((s) => s.systemSymbol)
            .toSet();
    // Any system which is not in our main cluster id.
    final unreachableSystems =
        systemsWithExplorers
            .where(
              (s) =>
                  systemConnectivity.existsJumpPathBetween(s, hqSystemSymbol),
            )
            .toSet();
    // And does not have a probe in it.
    final probes =
        ships.ships.where((s) => s.isProbe).map((s) => s.systemSymbol).toSet();
    final systemWithoutProbes = unreachableSystems
        .where((s) => !probes.contains(s))
        .sortedBy((s) => s.system);
    // return a probe buy job.
    if (systemWithoutProbes.isEmpty) {
      logger.info('All unreachable systems have probes!');
      return null;
    }
    const shipType = ShipType.PROBE;
    final systemSymbol = systemWithoutProbes.first;
    // TODO(eseidel): This should be a db query.
    final shipyardSymbol =
        shipyardListings
            .listingsInSystem(systemSymbol)
            .firstWhereOrNull((s) => s.hasShip(shipType))
            ?.waypointSymbol;
    if (shipyardSymbol == null) {
      logger.info("Can't find shipyard to buy probe in $systemSymbol");
      return null;
    }
    return ShipBuyJob(
      shipType: shipType,
      shipyardSymbol: shipyardSymbol,
      // Arbitrary credits value.
      minCreditsNeeded: 100000,
    );
  }

  /// Computes the next ship buy job.
  Future<ShipBuyJob?> _computeNextShipBuyJob(
    Database db,
    Api api,
    Caches caches,
    ShipyardListingSnapshot shipyardListings,
    ShipSnapshot ships,
  ) async {
    final unreachableProbeJob = await _unreachableSystemProbe(
      db,
      api,
      caches.agent,
      caches.systemConnectivity,
      shipyardListings,
      ships,
    );
    if (unreachableProbeJob != null) {
      return unreachableProbeJob;
    }

    final shipyardShips = await caches.static.shipyardShips.snapshot();
    final shipType = await shipToBuyFromPlan(
      ships,
      config.buyPlan,
      shipyardListings,
      shipyardShips,
    );
    if (shipType == null) {
      return null;
    }
    logger.info('Planning to buy $shipType');
    // TODO(eseidel): This uses command ship to compute the job, but
    // will happily give out the job to a non-command ship for execution.
    final commandShip = ships.ships.first;
    return _findBestPlaceToBuy(db, caches.routePlanner, commandShip, shipType);
  }

  /// Returns true if [ship] should start the buyShip behavior.
  Future<bool> shouldBuyShip(
    Database db,
    SystemConnectivity systemConnectivity,
    Ship ship,
    int credits,
  ) async {
    // Are there any other ships actively buying a ship?
    final states = await db.behaviorStatesWithBehavior(Behavior.buyShip);
    if (states.isNotEmpty) {
      return false;
    }
    // Do we have a ship we want to buy?
    final buyJob = nextShipBuyJob;
    if (buyJob == null) {
      return false;
    }
    // Do we have enough credits to buy a ship
    if (credits < buyJob.minCreditsNeeded + config.shipBuyBufferForTrading) {
      return false;
    }
    // Is this ship within the same system or the command ship?
    if (ship.systemSymbol != buyJob.shipyardSymbol.system && !ship.isCommand) {
      return false;
    }
    if (!systemConnectivity.existsJumpPathBetween(
      buyJob.shipyardSymbol.system,
      ship.systemSymbol,
    )) {
      return false;
    }

    // TODO(eseidel): See how far it is to the shipyard, only go if < 10 mins?
    // This may pick ships which are a long ways away from the shipyard.
    // But it at least avoids problems where the command ship is tied up
    // trading for hours many jumps away.
    return true;
  }

  /// Returns true if [ship] should start the mountFromBuy behavior.
  Future<bool> shouldBuyMount(Database db, Ship ship, int credits) async {
    // Only enforce "one at a time" until we some sort purchase authorization.
    // Are there any other ships actively buying mounts?
    final states = await db.behaviorStatesWithBehavior(Behavior.mountFromBuy);
    if (states.isNotEmpty) {
      return false;
    }
    // Does this ship have a mount it needs?
    final mountRequest = _mountRequests.firstWhereOrNull(
      (m) => m.shipSymbol == ship.symbol,
    );
    if (mountRequest == null) {
      return false;
    }
    // Do we have enough credits to buy a ship
    if (credits < mountRequest.creditsNeeded) {
      return false;
    }
    return true;
  }

  /// Computes the number of units needed to fulfill the given [contract].
  /// Includes units in flight.
  @visibleForTesting
  int remainingUnitsNeededForContract(
    BehaviorSnapshot behaviors,
    Contract contract,
    TradeSymbol tradeSymbol,
  ) {
    final unitsAssigned =
        behaviors
            .dealsInProgress()
            .where((d) => d.contractId == contract.id)
            .map((d) => d.maxUnitsToBuy)
            .sum;
    final neededGood = contract.goodNeeded(tradeSymbol);
    return neededGood!.remainingNeeded - unitsAssigned;
  }

  /// Computes the number of units needed to fulfill the given [construction].
  /// Includes units in flight.
  @visibleForTesting
  int remainingUnitsNeededForConstruction(
    BehaviorSnapshot behaviors,
    Construction construction,
    TradeSymbol tradeSymbol,
  ) {
    final unitsAssigned =
        behaviors
            .dealsInProgress()
            .where((d) => d.isConstructionDeal)
            .where(
              (d) => d.deal.destinationSymbol == construction.waypointSymbol,
            )
            .map((d) => d.maxUnitsToBuy)
            .sum;
    final material = construction.materialNeeded(tradeSymbol);
    return material!.remainingNeeded - unitsAssigned;
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

  /// Returns the siphon plan for the given [ship].
  // TODO(eseidel): call from or merge into getJobForShip.
  Future<ExtractionJob?> siphonJobForShip(
    Database db,
    SystemsCache systemsCache,
    ChartingCache chartingCache,
    AgentCache agentCache,
    Ship ship,
  ) async {
    final score =
        (await evaluateWaypointsForSiphoning(
          db,
          systemsCache,
          chartingCache,
          agentCache.headquartersSystemSymbol,
        )).firstOrNull;
    if (score == null) {
      return null;
    }
    return ExtractionJob(
      source: score.source,
      marketForGood: score.marketForGood,
      extractionType: ExtractionType.siphon,
    );
  }
}

int _maxContractUnitPurchasePrice(Contract contract, ContractDeliverGood good) {
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
  final maxUnitPrice = _maxContractUnitPurchasePrice(contract, good);
  final remainingUnits = good.unitsRequired - good.unitsFulfilled;
  return max(
    config.contractMinFloat,
    maxUnitPrice * remainingUnits + config.contractMinBuffer,
  );
}

/// Procurement contracts converted to sell opps.
Iterable<SellOpp> sellOppsForContracts(
  AgentCache agentCache,
  BehaviorSnapshot behaviors,
  ContractSnapshot contractSnapshot, {
  required int Function(BehaviorSnapshot, Contract, TradeSymbol)
  remainingUnitsNeededForContract,
}) sync* {
  for (final contract in affordableContracts(agentCache, contractSnapshot)) {
    for (final good in contract.terms.deliver) {
      final unitsNeeded = remainingUnitsNeededForContract(
        behaviors,
        contract,
        good.tradeSymbolObject,
      );
      if (unitsNeeded > 0) {
        yield SellOpp.fromContract(
          waypointSymbol: good.destination,
          tradeSymbol: good.tradeSymbolObject,
          contractId: contract.id,
          price: _maxContractUnitPurchasePrice(contract, good),
          maxUnits: unitsNeeded,
        );
      }
    }
  }
}

/// Returns the contracts we should consider for trading.
/// This is a subset of the active contracts that we have enough money to
/// complete.
Iterable<Contract> affordableContracts(
  AgentCache agentCache,
  ContractSnapshot contractsCache,
) {
  // We should only use the contract trader when we have enough credits to
  // complete the entire contract.  Otherwise we're just sinking credits into a
  // contract we can't complete yet when we could be using that money for other
  // trading.
  final credits = agentCache.agent.credits;
  return contractsCache.activeContracts.where(
    (c) => _minimumFloatRequired(c) <= credits,
  );
}

/// Procurement contracts converted to sell opps.
Iterable<SellOpp> sellOppsForConstruction(
  Construction construction, {
  required int Function(TradeSymbol) remainingUnitsNeeded,
}) sync* {
  if (construction.isComplete) {
    return;
  }

  for (final material in construction.materials) {
    final unitsNeeded = remainingUnitsNeeded(material.tradeSymbol);
    if (unitsNeeded > 0) {
      yield SellOpp.fromConstruction(
        waypointSymbol: construction.waypointSymbol,
        tradeSymbol: material.tradeSymbol,
        price: config.constructionMaxPurchasePrice[material.tradeSymbol]!,
        maxUnits: unitsNeeded,
      );
    }
  }
}

/// Compute the correct squad for the given [ship].
@visibleForTesting
ExtractionSquad? findSquadForShip(
  List<ExtractionSquad> squads,
  Ship ship, {
  required bool Function(Ship) useAsMinerHauler,
}) {
  if (squads.isEmpty) {
    return null;
  }

  // Score all squads based on how much they need this type of ship?
  // Add to the squad with the lowest score?
  final fleetRole = ship.fleetRole;
  // Hack for now to restrict to miners / surveyors.
  if (fleetRole != FleetRole.miner &&
      fleetRole != FleetRole.surveyor &&
      !useAsMinerHauler(ship)) {
    return null;
  }

  final lowestCount = squads.first.countOfRole(fleetRole);
  for (final squad in squads) {
    final count = squad.countOfRole(fleetRole);
    if (count < lowestCount) {
      return squad;
    }
  }
  // If we didn't find a squad, just return the first one.
  return squads.first;
}

/// Compute what our current mining squads should be.
Future<List<ExtractionSquad>> assignShipsToSquads(
  Database db,
  SystemsCache systemsCache,
  ChartingCache chartingCache,
  ShipSnapshot ships, {
  required SystemSymbol systemSymbol,
}) async {
  // Look at the top N mining scores.
  final scores =
      (await evaluateWaypointsForMining(
            db,
            systemsCache,
            chartingCache,
            systemSymbol,
          ))
          .where((m) => m.marketsTradeAllProducedGoods)
          .where(
            (m) => m.deliveryDistance < config.maxExtractionDeliveryDistance,
          )
          .toList();

  // Sort by distance from center of the system.
  final origin = WaypointPosition(0, 0, systemSymbol);
  scores.sortBy<num>((score) {
    final mineWaypoint = systemsCache.waypoint(score.source);
    final distance = mineWaypoint.position.distanceTo(origin);
    return distance.toInt();
  });
  // Divide our current ships into N squads.
  final squads = List.generate(scores.length, (index) {
    final score = scores[index];
    final job = ExtractionJob(
      source: score.source,
      marketForGood: score.marketForGood,
      extractionType: ExtractionType.mine,
    );
    return ExtractionSquad(job);
  });

  // TODO(eseidel): Should use a dynamic count.
  final minerHaulerSymbols = ships.ships
      .where((s) => s.isHauler)
      .map((s) => s.symbol)
      .sorted()
      .take(config.minerHaulerCount);
  bool useAsMinerHauler(Ship ship) {
    return config.enableMining && minerHaulerSymbols.contains(ship.symbol);
  }

  // Go through and assign all ships to squads.
  for (final ship in ships.ships) {
    findSquadForShip(
      squads,
      ship,
      useAsMinerHauler: useAsMinerHauler,
    )?.ships.add(ship);
  }
  return squads;
}

/// Returns the next ship to buy from the given [shipPlan].
Future<ShipType?> shipToBuyFromPlan(
  ShipSnapshot ships,
  List<ShipType> shipPlan,
  ShipyardListingSnapshot shipyardListings,
  ShipyardShipSnapshot shipyardShips,
) async {
  final counts = <ShipType, int>{};
  for (final shipType in shipPlan) {
    counts[shipType] = (counts[shipType] ?? 0) + 1;
    final fleetCount = ships.countOfType(shipyardShips, shipType);
    if (fleetCount == null) {
      logger.warn('Unknown count for $shipType');
      return null;
    }
    // If we have bought this ship type enough times, go next.
    if (fleetCount >= counts[shipType]!) {
      continue;
    }
    // If we should buy this one but haven't found it yet, buy nothing.
    // TODO(eseidel): This fails early before we have prices.
    if (!shipyardListings.knowOfShipyardWithShip(shipType)) {
      logger.warn('No prices for $shipType');
      return null;
    }
    // TODO(eseidel): This doesn't take reachability into account, we might
    // know of a shipyard selling shipType, but not be able to reach it.
    return shipType;
  }
  logger.info('All ships already purchased in plan.');
  // We walked off the end of our plan.
  return null;
}

class _ImportCollector extends SupplyLinkVisitor {
  _ImportCollector(this.db);
  final Database db;
  final List<MarketPrice> imports = [];

  @override
  Future<void> visitManufacture(
    ManufactureLink link, {
    required int depth,
  }) async {
    for (final input in link.inputs.keys) {
      final price = await db.marketPriceAt(link.waypointSymbol, input);
      if (price != null) {
        imports.add(price);
      }
    }
  }
}

/// Computes the market subsidies for the current construction job.
/// This may return multiple SellOpps which are the same if the same
/// good is used in multiple supply chains (e.g. copper).  We could remove
/// that behavior if needed, but currently that will just cause twice as many
/// traders to service that route as normal which is probably not bad.
Future<List<SellOpp>> computeConstructionMaterialSubsidies(
  Database db,
  SystemsCache systems,
  TradeExportSnapshot exports,
  MarketListingSnapshot marketListings,
  ChartingSnapshot charting,
  Construction construction,
) async {
  final neededExports = construction.materials
      .where((m) => m.required_ > m.fulfilled)
      .map((m) => m.tradeSymbol);
  final sellOpps = <SellOpp>[];
  for (final symbol in neededExports) {
    final chain = SupplyChainBuilder(
      systems: systems,
      exports: exports,
      marketListings: marketListings,
      charting: charting,
    ).buildChainTo(symbol, construction.waypointSymbol);
    if (chain != null) {
      sellOpps.addAll(await constructionSubsidiesForSupplyChain(db, chain));
    }
  }
  return sellOpps;
}

/// Computes the market subsidies for a given supply chain.
Future<List<SellOpp>> constructionSubsidiesForSupplyChain(
  Database db,
  SupplyLink chain,
) async {
  final subsidies = <SellOpp>[];
  final collector = _ImportCollector(db);
  await chain.accept(collector);

  for (final price in collector.imports) {
    final subsidizedSellPrice =
        price.sellPrice + config.subsidyForSupplyLevel(price.supply);
    final subsidizedPrice = price.copyWith(sellPrice: subsidizedSellPrice);
    subsidies.add(SellOpp.fromMarketPrice(subsidizedPrice));
  }
  return subsidies;
}
