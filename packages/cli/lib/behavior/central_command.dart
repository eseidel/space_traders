import 'dart:math';

import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/charter.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/extraction_score.dart';
import 'package:cli/logger.dart';
import 'package:cli/mining.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// BehaviorCache extension methods for CentralCommand.
extension BehaviorCacheExtensions on BehaviorCache {
  /// Returns all deals in progress.
  Iterable<CostedDeal> dealsInProgress() sync* {
    for (final state in states) {
      final deal = state.deal;
      if (deal != null) {
        yield deal;
      }
    }
  }
}

/// Central command for the fleet.
class CentralCommand {
  /// Create a new central command.
  CentralCommand({
    required BehaviorCache behaviorCache,
    required ShipCache shipCache,
  })  : _behaviorCache = behaviorCache,
        _shipCache = shipCache;

  final BehaviorCache _behaviorCache;
  final ShipCache _shipCache;
  bool _haveEscapedStartingSystem = false;

  /// Per-system price age data used by system watchers.
  final Map<SystemSymbol, Duration> _maxPriceAgeForSystem = {};

  /// The next planned ship buy job.
  /// This is the start of an imagined job queue system, whereby we pre-populate
  /// BehaviorStates with jobs when handing them out to ships.
  ShipBuyJob? _nextShipBuyJob;

  /// The current construction job.  Visible so that a script can set it.
  Construction? activeConstruction;

  /// The current mining squads.
  List<ExtractionSquad> miningSquads = [];

  /// Mounts we know of a place we can buy.
  final Set<ShipMountSymbolEnum> _availableMounts = {};

  final Map<ShipSymbol, SystemSymbol> _assignedSystemsForSatellites =
      Map.from(config.probeAssignments);

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
  bool get isContractTradingEnabled => true;

  /// Returns true if construction trading is enabled.
  bool get isConstructionTradingEnabled => true;

  /// Minimum profit per second we expect this ship to make.
  // Should set this based on the ship type and how much we expect to earn
  // from other sources (e.g. hauling mining goods?)
  int expectedCreditsPerSecond(Ship ship) {
    // If we're stuck in our own system, any trades are better than exploring.
    if (!_haveEscapedStartingSystem && ship.fleetRole == FleetRole.trader) {
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

  /// Returns the system symbol we should assign the given [ship] to.
  SystemSymbol? assignedSystemForSatellite(Ship ship) =>
      _assignedSystemsForSatellites[ship.shipSymbol];

  /// Returns the mining squad for the given [ship].
  ExtractionSquad? squadForShip(Ship ship) {
    var squad = miningSquads.firstWhereOrNull((s) => s.contains(ship));
    // Handle the case of a newly purchased ship.
    if (squad == null) {
      squad = findSquadForShip(miningSquads, ship);
      squad?.ships.add(ship);
    }
    return squad;
  }

  /// What template should we use for the given ship?
  ShipTemplate? templateForShip(
    Ship ship,
  ) {
    final squad = squadForShip(ship);
    if (squad == null) {
      return null;
    }
    return squad.templateForShip(ship, availableMounts: _availableMounts);
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

  /// Returns an initialized behavior state for the given [ship] to start
  /// its next job.
  BehaviorState getJobForShip(Ship ship, int credits) {
    final shipSymbol = ship.shipSymbol;
    BehaviorState toState(Behavior behavior) {
      return BehaviorState(shipSymbol, behavior);
    }

    bool enabled(Behavior behavior) {
      return !_behaviorCache.isBehaviorDisabledForShip(ship, behavior);
    }

    if (ship.isOutOfFuel) {
      return toState(Behavior.idle);
    }
    // We'll always upgrade a ship as our best option.
    if (enabled(Behavior.mountFromBuy) && shouldBuyMount(ship, credits)) {
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
    if (enabled(Behavior.buyShip) && shouldBuyShip(ship, credits)) {
      return BehaviorState(
        shipSymbol,
        Behavior.buyShip,
        shipBuyJob: takeShipBuyJob(),
      );
    }

    final squad = squadForShip(ship);
    if (squad != null) {
      var behavior = {
        FleetRole.miner: Behavior.miner,
        FleetRole.surveyor: Behavior.surveyor,
        FleetRole.siphoner: Behavior.siphoner,
      }[ship.fleetRole];
      if (behavior == null && ship.isHauler && enabled(Behavior.minerHauler)) {
        behavior = Behavior.minerHauler;
      }
      if (behavior != null && enabled(behavior)) {
        return BehaviorState(
          shipSymbol,
          behavior,
          extractionJob: squad.job,
        );
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
        if (!_behaviorCache.isBehaviorDisabledForShip(ship, behavior)) {
          return toState(behavior);
        }
      }
    } else {
      logger.warn('${ship.fleetRole} has no specified behaviors, idling.');
    }
    return toState(Behavior.idle);
  }

  /// Procurement contracts converted to sell opps.
  Iterable<SellOpp> contractSellOpps(
    AgentCache agentCache,
    ContractCache contractCache,
  ) {
    return sellOppsForContracts(
      agentCache,
      contractCache,
      remainingUnitsNeededForContract: remainingUnitsNeededForContract,
    );
  }

  /// SellOpps to complete the current construction job.
  Iterable<SellOpp> constructionSellOpps() {
    if (activeConstruction == null) {
      return [];
    }
    return sellOppsForConstruction(
      activeConstruction!,
      remainingUnitsNeeded: (tradeSymbol) {
        return remainingUnitsNeededForConstruction(
          activeConstruction!,
          tradeSymbol,
        );
      },
    );
  }

  /// Find next deal for the given [ship], considering all deals in progress.
  CostedDeal? findNextDealAndLog(
    AgentCache agentCache,
    ConstructionCache constructionCache,
    ContractCache contractCache,
    MarketPrices marketPrices,
    SystemsCache systemsCache,
    SystemConnectivity systemConnectivity,
    RoutePlanner routePlanner,
    Ship ship, {
    required int maxTotalOutlay,
    WaypointSymbol? overrideStartSymbol,
  }) {
    final startSymbol = overrideStartSymbol ?? ship.waypointSymbol;

    final extraSellOpps = <SellOpp>[];
    if (isConstructionTradingEnabled) {
      extraSellOpps.addAll(constructionSellOpps());
    }
    if (isContractTradingEnabled) {
      extraSellOpps.addAll(contractSellOpps(agentCache, contractCache));
    }
    if (extraSellOpps.isNotEmpty) {
      final opp = extraSellOpps.first;
      logger.detail(
        'Including contract sell opp: ${opp.maxUnits} ${opp.tradeSymbol} '
        '@ ${creditsString(opp.price)} -> ${opp.waypointSymbol}',
      );
    }
    final deals = scanAndFindDeals(
      systemsCache,
      systemConnectivity,
      marketPrices,
      routePlanner,
      maxTotalOutlay: maxTotalOutlay,
      startSymbol: startSymbol,
      extraSellOpps: extraSellOpps,
      shipSpec: ship.shipSpec,
      filter: avoidDealsInProgress(_behaviorCache.dealsInProgress()),
    );

    logger.info('Found ${deals.length} deals for ${ship.shipSymbol} from '
        '$startSymbol');
    for (final deal in deals) {
      logger.detail(describeCostedDeal(deal));
    }
    return deals.firstOrNull;
  }

  /// Returns the next waypoint symbol to chart.
  Future<WaypointSymbol?> nextWaypointToChart(
    SystemsCache systems,
    WaypointCache waypoints,
    SystemConnectivity connectivity,
    Ship ship,
  ) async {
    final charterSystems = otherCharterSystems(ship.shipSymbol).toSet();

    // Walk waypoints as far out as we can see until we find one missing
    // a chart or market data and route to there.
    final destinationSymbol = await nextUnchartedWaypointSymbol(
      systems,
      waypoints,
      connectivity,
      ship,
      startSystemSymbol: ship.systemSymbol,
      filter: (SystemWaypoint waypoint) {
        // Don't bother charting Asteroids for now.
        if (waypoint.isAsteroid) {
          return false;
        }
        // Don't visit systems we already have a charter in.
        return !charterSystems.contains(waypoint.systemSymbol);
      },
    );
    return destinationSymbol;
  }

  /// Returns other systems containing ships with [behavior].
  Iterable<SystemSymbol> _otherSystemsWithBehavior(
    ShipSymbol thisShipSymbol,
    Behavior behavior,
  ) {
    return _otherWaypointsWithBehavior(thisShipSymbol, behavior)
        .map((s) => s.systemSymbol);
  }

  /// Returns other systems containing ships with [behavior].
  Iterable<WaypointSymbol> _otherWaypointsWithBehavior(
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
      // Yield both the ship's current waypoint and its destination.
      final ship = _shipCache.ship(state.shipSymbol);
      yield ship.waypointSymbol;

      final destination = state.routePlan?.endSymbol;
      if (destination != null) {
        yield destination;
      }
    }
  }

  /// Returns all systems containing explorers or explorer destinations.
  Iterable<WaypointSymbol> waypointsToAvoidInSystem(
    SystemSymbol systemSymbol,
    ShipSymbol thisShipSymbol,
  ) =>
      _otherWaypointsWithBehavior(thisShipSymbol, Behavior.systemWatcher)
          .where((s) => s.systemSymbol == systemSymbol);

  /// Returns all systems containing charters or charter destinations.
  Iterable<SystemSymbol> otherCharterSystems(ShipSymbol thisShipSymbol) =>
      _otherSystemsWithBehavior(thisShipSymbol, Behavior.charter);

  /// Returns all systems containing traders or trader destinations.
  Iterable<SystemSymbol> otherTraderSystems(ShipSymbol thisShipSymbol) =>
      _otherSystemsWithBehavior(thisShipSymbol, Behavior.trader);

  Future<void> _queueMountRequests(
    Caches caches,
  ) async {
    for (final ship in _shipCache.ships) {
      if (_mountRequests.any((m) => m.shipSymbol == ship.shipSymbol)) {
        return;
      }
      // Don't queue a new mount request if we're currently executing one.
      if (_behaviorCache.getBehavior(ship.shipSymbol)?.behavior ==
          Behavior.mountFromBuy) {
        continue;
      }
      final template = templateForShip(ship);
      if (template == null) {
        continue;
      }
      final expectedCreditsPerSecond = this.expectedCreditsPerSecond(ship);
      final request = await mountRequestForShip(
        this,
        caches,
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
  void updateAvailableMounts(MarketPrices marketPrices) {
    for (final mountSymbol in ShipMountSymbolEnum.values) {
      if (_availableMounts.contains(mountSymbol)) {
        continue;
      }
      final isAvailable = marketPrices.havePriceFor(
        tradeSymbolForMountSymbol(mountSymbol),
      );
      if (isAvailable) {
        _availableMounts.add(mountSymbol);
      }
    }
  }

  Construction? _computeActiveConstruction(Caches caches) {
    if (!isConstructionTradingEnabled) {
      return null;
    }

    if (caches.agent.agent.credits < config.constructionMinCredits) {
      return null;
    }

    final systemSymbol = caches.agent.headquartersSystemSymbol;
    final jumpGate = caches.systems.jumpGateWaypointForSystem(systemSymbol);
    return jumpGate == null
        ? null
        : caches.construction[jumpGate.waypointSymbol];
  }

  bool _computeHaveEscapedStartingSystem(Caches caches) {
    if (_haveEscapedStartingSystem) {
      return true;
    }
    // We'll assume that if all the ships are in the same system we've
    // not yet constructed our jump gate.
    final systemSymbols = Set<SystemSymbol>.from(
      _shipCache.ships.map((s) => s.nav.systemSymbolObject),
    );
    return systemSymbols.length > 1;
  }

  /// Give central planning a chance to advance.
  /// Currently only run once every N loops (currently 50).
  Future<void> advanceCentralPlanning(Api api, Caches caches) async {
    caches.updateRoutingCaches();

    miningSquads = await assignShipsToSquads(
      caches.systems,
      caches.waypoints,
      caches.marketListings,
      _shipCache,
      systemSymbol: caches.agent.headquartersSystemSymbol,
    );

    _nextShipBuyJob ??= await _computeNextShipBuyJob(api, caches);
    updateAvailableMounts(caches.marketPrices);
    await _queueMountRequests(caches);

    activeConstruction = _computeActiveConstruction(caches);
    _haveEscapedStartingSystem = _computeHaveEscapedStartingSystem(caches);
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
      (m) => m.shipSymbol == ship.shipSymbol,
      orElse: () => throw ArgumentError('No mount request for $ship'),
    );
    _mountRequests.remove(mountRequest);
    return mountRequest;
  }

  Future<ShipBuyJob?> _findBestPlaceToBuy(
    Caches caches,
    ShipType shipType,
  ) async {
    // TODO(eseidel): This uses command ship to compute the job, but
    // will happily give out the job to a non-command ship for execution.
    final commandShip = _shipCache.ships.first;
    final trip = findBestShipyardToBuy(
      caches.shipyardPrices,
      caches.routePlanner,
      commandShip,
      shipType,
      expectedCreditsPerSecond: expectedCreditsPerSecond(commandShip),
    );
    if (trip == null) {
      return null;
    }
    final recentPrice = caches.shipyardPrices.recentPurchasePrice(
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

  /// Computes the next ship buy job.
  Future<ShipBuyJob?> _computeNextShipBuyJob(Api api, Caches caches) async {
    final shipType = shipToBuyFromPlan(
      _shipCache,
      config.buyPlan,
      caches.shipyardPrices,
      caches.static.shipyardShips,
    );
    if (shipType == null) {
      return null;
    }
    logger.info('Planning to buy $shipType');
    return _findBestPlaceToBuy(caches, shipType);
  }

  /// Returns true if [ship] should start the buyShip behavior.
  bool shouldBuyShip(Ship ship, int credits) {
    // Are there any other ships actively buying a ship?
    if (_behaviorCache.states.any((s) => s.behavior == Behavior.buyShip)) {
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
    if (ship.systemSymbol != buyJob.shipyardSymbol.systemSymbol &&
        !ship.isCommand) {
      return false;
    }
    // TODO(eseidel): See how far it is to the shipyard, only go if < 10 mins?
    // For now just hacking to be command ship.
    return ship.isCommand;
  }

  /// Returns true if [ship] should start the mountFromBuy behavior.
  bool shouldBuyMount(Ship ship, int credits) {
    // Only enforce "one at a time" until we some sort purchase authoriziation.
    // Are there any other ships actively buying mounts?
    final otherShipsAreBuyingMounts = _behaviorCache.states.any(
      (s) => s.behavior == Behavior.mountFromBuy,
    );
    if (otherShipsAreBuyingMounts) {
      return false;
    }
    // Does this ship have a mount it needs?
    final mountRequest =
        _mountRequests.firstWhereOrNull((m) => m.shipSymbol == ship.shipSymbol);
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
    Contract contract,
    TradeSymbol tradeSymbol,
  ) {
    final unitsAssigned = _behaviorCache
        .dealsInProgress()
        .where((d) => d.contractId == contract.id)
        .fold<int>(0, (sum, deal) => sum + deal.maxUnitsToBuy);
    final neededGood = contract.goodNeeded(tradeSymbol);
    return neededGood!.unitsRequired -
        neededGood.unitsFulfilled -
        unitsAssigned;
  }

  /// Computes the number of units needed to fulfill the given [construction].
  /// Includes units in flight.
  @visibleForTesting
  int remainingUnitsNeededForConstruction(
    Construction construction,
    TradeSymbol tradeSymbol,
  ) {
    final unitsAssigned = _behaviorCache
        .dealsInProgress()
        .where((d) => d.isConstructionDeal)
        .where((d) => d.deal.destinationSymbol == construction.waypointSymbol)
        .fold<int>(0, (sum, deal) => sum + deal.maxUnitsToBuy);
    final neededGood = construction.materials.firstWhere(
      (m) => m.tradeSymbol == tradeSymbol,
    );
    return neededGood.required_ - neededGood.fulfilled - unitsAssigned;
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
    WaypointCache waypointCache,
    SystemsCache systemsCache,
    MarketListingCache marketListings,
    AgentCache agentCache,
    Ship ship,
  ) async {
    final score = (await evaluateWaypointsForSiphoning(
      waypointCache,
      systemsCache,
      marketListings,
      agentCache.headquartersSystemSymbol,
    ))
        .firstOrNull;
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

int _maxContractUnitPurchasePrice(
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
  ContractCache contractCache, {
  required int Function(Contract, TradeSymbol) remainingUnitsNeededForContract,
}) sync* {
  for (final contract in affordableContracts(agentCache, contractCache)) {
    for (final good in contract.terms.deliver) {
      final unitsNeeded = remainingUnitsNeededForContract(
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

/// Returns the ship symbols for all idle haulers.
List<ShipSymbol> idleHaulerSymbols(
  ShipCache shipCache,
  BehaviorCache behaviorCache,
) {
  final haulerSymbols =
      shipCache.ships.where((s) => s.isHauler).map((s) => s.shipSymbol);
  final idleBehaviors = [
    Behavior.idle,
    Behavior.charter,
  ];
  final idleHaulerStates = behaviorCache.states
      .where((s) => haulerSymbols.contains(s.shipSymbol))
      .where((s) => idleBehaviors.contains(s.behavior))
      .toList();
  return idleHaulerStates.map((s) => s.shipSymbol).toList();
}

/// Compute the correct squad for the given [ship].
@visibleForTesting
ExtractionSquad? findSquadForShip(List<ExtractionSquad> squads, Ship ship) {
  if (squads.isEmpty) {
    return null;
  }

  // Score all squads based on how much they need this type of ship?
  // Add to the squad with the lowest score?
  final fleetRole = ship.fleetRole;
  // Hack for now to restrict to miners / surveyors.
  if (fleetRole != FleetRole.miner &&
      fleetRole != FleetRole.surveyor &&
      !config.minerHaulerSymbols.contains(ship.shipSymbol)) {
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
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketListingCache marketListings,
  ShipCache shipCache, {
  required SystemSymbol systemSymbol,
}) async {
  // Look at the top N mining scores.
  final scores = (await evaluateWaypointsForMining(
    waypointCache,
    systemsCache,
    marketListings,
    systemSymbol,
  ))
      .where((m) => m.marketsTradeAllProducedGoods)
      .where((m) => m.deliveryDistance < config.maxExtractionDeliveryDistance)
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
  // Go through and assign all ships to squads.
  for (final ship in shipCache.ships) {
    findSquadForShip(squads, ship)?.ships.add(ship);
  }
  return squads;
}

/// Returns the next ship to buy from the given [shipPlan].
ShipType? shipToBuyFromPlan(
  ShipCache shipCache,
  List<ShipType> shipPlan,
  ShipyardPrices shipyardPrices,
  ShipyardShipCache shipyardShips,
) {
  final counts = <ShipType, int>{};
  for (final shipType in shipPlan) {
    counts[shipType] = (counts[shipType] ?? 0) + 1;
    final fleetCount = shipCache.countOfType(shipyardShips, shipType);
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
    // We should store ShipListings separate from ShipyardPrices.
    if (!shipyardPrices.havePriceFor(shipType)) {
      logger.warn('No prices for $shipType');
      return null;
    }
    // Buy this one!
    return shipType;
  }
  logger.info('All ships already purchased in plan.');
  // We walked off the end of our plan.
  return null;
}
