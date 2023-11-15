import 'dart:math';

import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/mine_scores.dart';
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

  /// How old can explorer data be before we refresh it?
  Duration _maxAgeForExplorerData = const Duration(days: 3);

  /// The next planned ship buy job.
  /// This is the start of an imagined job queue system, whereby we pre-populate
  /// BehaviorStates with jobs when handing them out to ships.
  ShipBuyJob? _nextShipBuyJob;

  /// The current construction job.
  Construction? _activeConstruction;

  /// The current mining squads.
  List<MiningSquad> miningSquads = [];

  /// The current construction job, temporary hack.
  void setActiveConstruction(Construction? construction) {
    _activeConstruction = construction;
  }

  /// Mounts we know of a place we can buy.
  final Set<ShipMountSymbolEnum> _availableMounts = {};

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

  /// Minimum profit per second we expect this ship to make.
  // Should set this based on the ship type and how much we expect to earn
  // from other sources (e.g. hauling mining goods?)
  int expectedCreditsPerSecond(Ship ship) {
    // If we're stuck in our own system, any trades are better than exploring.
    // if (!_haveEscapedStartingSystem && ship.isHauler) {
    //   return 1;
    // }
    // This should depend on phase and ship type?
    return 4;
  }

  /// Data older than this will be refreshed by explorers.
  /// Explorers will shorten this time if they run out of places to explore.
  Duration get maxAgeForExplorerData => _maxAgeForExplorerData;

  /// Shorten the max age for explorer data.
  Duration shortenMaxAgeForExplorerData() => _maxAgeForExplorerData ~/= 2;

  /// Returns the mining squad for the given [ship].
  MiningSquad? squadForShip(Ship ship) {
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
    BehaviorState toState(Behavior behavior) {
      return BehaviorState(ship.shipSymbol, behavior);
    }

    if (ship.isOutOfFuel) {
      return toState(Behavior.idle);
    }
    // We'll always upgrade a ship as our best option.
    if (shouldBuyMount(ship, credits)) {
      final request = _takeMountRequest(ship);
      shipInfo(ship, 'Starting buy mount ${request.mountSymbol}');
      return BehaviorState(ship.shipSymbol, Behavior.mountFromBuy)
        ..buyJob = request.buyJob
        ..mountJob = request.mountJob;
    }
    // Otherwise buy a ship if we can.
    if (shouldBuyShip(ship, credits)) {
      return BehaviorState(ship.shipSymbol, Behavior.buyShip)
        ..shipBuyJob = takeShipBuyJob();
    }

    final squad = squadForShip(ship);
    if (squad != null) {
      if (ship.fleetRole == FleetRole.miner) {
        return BehaviorState(ship.shipSymbol, Behavior.miner)
          ..mineJob = squad.job;
      } else if (ship.fleetRole == FleetRole.surveyor) {
        return BehaviorState(ship.shipSymbol, Behavior.surveyor)
          ..mineJob = squad.job;
      }
    }

    // Otherwise start any other job.
    return toState(chooseNewBehaviorFor(ship, credits));
  }

  // Consider a config file like:
  // https://gist.github.com/whyando/fed97534173437d8234be10ac03595e0
  // instead of having this dynamic behavior function.
  /// What behavior should the given ship be doing?
  Behavior chooseNewBehaviorFor(Ship ship, int credits) {
    // final shipCount = _shipCache.ships.length;

    final behaviors = {
      FleetRole.command: [
        // Will only trade if we can make 6/s or more.
        // There are commonly 20c/s trades in the starting system, and at
        // the minimum we want to accept the contract.
        // Might want to consider limiting to short trades (< 5 mins) to avoid
        // tying up capital early.
        Behavior.trader,
        // Early on the command ship makes about 5c/s vs. ore hounds making
        // 6c/s. It's a better surveyor than miner. Especially when enabling
        // mining drones.
        // if (shipCount > 3 && shipCount < 10) Behavior.surveyor,
        // Mining is more profitable than siphoning I think?
        Behavior.siphoner,
        Behavior.miner,
      ],
      FleetRole.trader: [
        Behavior.trader,
        // Would rather have Haulers idle, than explore if fuel costs are high.
        // Behavior.explorer,
      ],
      FleetRole.miner: [Behavior.miner],
      FleetRole.surveyor: [Behavior.surveyor],
      FleetRole.siphoner: [Behavior.siphoner],
      FleetRole.explorer: [Behavior.explorer],
    }[ship.fleetRole];
    if (behaviors != null) {
      for (final behavior in behaviors) {
        if (!_behaviorCache.isBehaviorDisabledForShip(ship, behavior)) {
          return behavior;
        }
      }
    } else {
      logger.warn('${ship.fleetRole} has no specified behaviors, idling.');
    }
    return Behavior.idle;
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
    if (_activeConstruction == null) {
      return [];
    }
    return sellOppsForConstruction(
      _activeConstruction!,
      remainingUnitsNeeded: (tradeSymbol) {
        return remainingUnitsNeededForConstruction(
          _activeConstruction!,
          tradeSymbol,
        );
      },
    );
  }

  /// Find next deal for the given [ship], considering all deals in progress.
  CostedDeal? findNextDeal(
    AgentCache agentCache,
    ConstructionCache constructionCache,
    ContractCache contractCache,
    MarketPrices marketPrices,
    SystemsCache systemsCache,
    RoutePlanner routePlanner,
    Ship ship, {
    required int maxTotalOutlay,
    required int maxWaypoints,
    WaypointSymbol? overrideStartSymbol,
  }) {
    final startSymbol = overrideStartSymbol ?? ship.waypointSymbol;
    final systemSymbol = overrideStartSymbol != null
        ? overrideStartSymbol.systemSymbol
        : ship.systemSymbol;

    final inProgress = _behaviorCache.dealsInProgress().toList();
    // Avoid having two ships working on the same deal since by the time the
    // second one gets there the prices will have changed.
    // Note this does not check destination, so should still allow two
    // ships to work on the same contract.
    bool filter(Deal deal) {
      return inProgress.every((d) {
        // Deals need to differ in their source *or* their trade symbol
        // for us to consider them.
        return d.deal.sourceSymbol != deal.sourceSymbol ||
            d.deal.tradeSymbol != deal.tradeSymbol;
      });
    }

    /// This should decide if contract trading is enabled, and if it is
    /// include extra SellOpps for the contract goods.
    final extraSellOpps = <SellOpp>[...constructionSellOpps()];
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

    final marketScan = scanNearbyMarkets(
      systemsCache,
      marketPrices,
      systemSymbol: systemSymbol,
      maxWaypoints: maxWaypoints,
    );
    final deals = findDealsFor(
      marketPrices,
      systemsCache,
      routePlanner,
      marketScan,
      maxTotalOutlay: maxTotalOutlay,
      extraSellOpps: extraSellOpps,
      filter: filter,
      startSymbol: startSymbol,
      fuelCapacity: ship.fuel.capacity,
      // Using capacity, rather than availableSpace, since the
      // trader logic tries to clear out the hold.
      cargoCapacity: ship.cargo.capacity,
      shipSpeed: ship.engine.speed,
    );
    logger.info('Found ${deals.length} deals for ${ship.shipSymbol} from '
        '$startSymbol');
    for (final deal in deals) {
      logger.detail(describeCostedDeal(deal));
    }
    return deals.firstOrNull;
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
  Iterable<WaypointSymbol> otherExplorerWaypoints(ShipSymbol thisShipSymbol) =>
      _otherWaypointsWithBehavior(thisShipSymbol, Behavior.explorer);

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
    final systemSymbol = caches.agent.headquarters(caches.systems).systemSymbol;
    final jumpGate = caches.systems.jumpGateWaypointForSystem(systemSymbol);
    return jumpGate == null
        ? null
        : caches.construction.constructionForSymbol(jumpGate.waypointSymbol);
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
  Future<void> advanceCentralPlanning(Api api, Caches caches) async {
    final hq = caches.agent.agent.headquartersSymbol;
    miningSquads = await assignShipsToSquads(
      caches.waypoints,
      caches.marketListings,
      _shipCache,
      systemSymbol: hq.systemSymbol,
    );

    _nextShipBuyJob ??= await _computeNextShipBuyJob(api, caches);
    updateAvailableMounts(caches.marketPrices);
    await _queueMountRequests(caches);

    _activeConstruction = _computeActiveConstruction(caches);
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

  /// Returns the next ship to buy from the given [shipPlan].
  @visibleForTesting
  ShipType? shipToBuyFromPlan(
    List<ShipType> shipPlan,
    ShipyardPrices shipyardPrices,
    ShipyardShipCache shipyardShips,
  ) {
    final counts = <ShipType, int>{};
    for (final shipType in shipPlan) {
      counts[shipType] = (counts[shipType] ?? 0) + 1;
      final fleetCount = _shipCache.countOfType(shipyardShips, shipType);
      if (fleetCount == null) {
        logger.warn('Unknown count for $shipType');
        return null;
      }
      // If we have bought this ship type enough times, go next.
      if (fleetCount >= counts[shipType]!) {
        continue;
      }
      // If we should buy this one but haven't found it yet, buy nothing.
      if (!shipyardPrices.havePriceFor(shipType)) {
        return null;
      }
      // Buy this one!
      return shipType;
    }
    // We walked off the end of our plan.
    return null;
  }

  /// Computes the next ship buy job.
  Future<ShipBuyJob?> _computeNextShipBuyJob(Api api, Caches caches) async {
    // final buyPlan = [
    //   ShipType.MINING_DRONE,
    //   ShipType.SIPHON_DRONE,
    //   ShipType.SURVEYOR,
    //   ShipType.LIGHT_HAULER,
    //   ShipType.MINING_DRONE,
    //   ShipType.SURVEYOR,
    //   ShipType.SIPHON_DRONE,
    //   ShipType.LIGHT_HAULER,
    //   ShipType.MINING_DRONE,
    //   ShipType.SURVEYOR,
    //   ShipType.SIPHON_DRONE,
    //   ShipType.LIGHT_HAULER,
    //   ShipType.MINING_DRONE,
    //   ShipType.SURVEYOR,
    //   ShipType.SIPHON_DRONE,
    //   ShipType.LIGHT_HAULER,
    // ];
    // final shipType = shipToBuyFromPlan(
    //   buyPlan,
    //   caches.shipyardPrices,
    //   caches.static.shipyardShips,
    // );
    // if (shipType == null) {
    //   return null;
    // }
    // logger.info('Planning to buy $shipType');
    // return _findBestPlaceToBuy(caches, shipType);

    bool shouldBuy(ShipType shipType, int count) {
      final typeCount =
          _shipCache.countOfType(caches.static.shipyardShips, shipType) ?? 0;
      return caches.shipyardPrices.havePriceFor(shipType) && typeCount < count;
    }

    final squadCount = miningSquads.length;

    if (shouldBuy(ShipType.LIGHT_HAULER, 10)) {
      return _findBestPlaceToBuy(caches, ShipType.LIGHT_HAULER);
    }
    // // These numbers should be based on squad sizes so that we always have
    // // full squads.
    // if (shouldBuy(ShipType.ORE_HOUND, 10)) {
    //   return _findBestPlaceToBuy(caches, ShipType.ORE_HOUND);
    // }
    if (shouldBuy(ShipType.MINING_DRONE, squadCount * 2)) {
      return _findBestPlaceToBuy(caches, ShipType.MINING_DRONE);
    }
    // if (shouldBuy(ShipType.SIPHON_DRONE, 10)) {
    //   return _findBestPlaceToBuy(caches, ShipType.SIPHON_DRONE);
    // }
    if (shouldBuy(ShipType.SURVEYOR, squadCount)) {
      return _findBestPlaceToBuy(caches, ShipType.SURVEYOR);
    }
    // if (shouldBuy(ShipType.HEAVY_FREIGHTER, 10)) {
    //   return _findBestPlaceToBuy(caches, ShipType.HEAVY_FREIGHTER);
    // }
    // if (shouldBuy(ShipType.PROBE, 3)) {
    //   return _findBestPlaceToBuy(caches, ShipType.PROBE);
    // }
    return null;
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
    // FIXME(eseidel): Keep around 100,000 for trading
    if (credits < buyJob.minCreditsNeeded + 100000) {
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
    // Only enforce the "one at a time" when we have less than 10M credits.
    // The 10M is mostly a hack to allow deploying changes to mounts quickly
    // late game.
    if (credits < 10000000) {
      // Are there any other ships actively buying mounts?
      final otherShipsAreBuyingMounts = _behaviorCache.states.any(
        (s) => s.behavior == Behavior.mountFromBuy,
      );
      if (otherShipsAreBuyingMounts) {
        return false;
      }
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

  /// Computes the number of units needed to fulfill the given [construction].
  /// Includes units in flight.
  @visibleForTesting
  int remainingUnitsNeededForConstruction(
    Construction construction,
    TradeSymbol tradeSymbol,
  ) {
    var unitsAssigned = 0;
    for (final shipSymbol in _shipCache.shipSymbols) {
      final deal = _behaviorCache.getBehavior(shipSymbol)?.deal;
      if (deal == null) {
        continue;
      }
      if (deal.deal.destinationSymbol != construction.waypointSymbol) {
        continue;
      }
      unitsAssigned += deal.maxUnitsToBuy;
    }
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
  Future<MineJob?> siphonJobForShip(
    WaypointCache waypointCache,
    MarketListingCache marketListings,
    AgentCache agentCache,
    Ship ship,
  ) async {
    final hq = agentCache.agent.headquartersSymbol;
    final score = (await evaluateWaypointsForSiphoning(
      waypointCache,
      marketListings,
      hq.systemSymbol,
    ))
        .firstWhereOrNull((m) => m.marketTradesAllProducedGoods);
    if (score == null) {
      return null;
    }
    // Currently reusing MineJob.
    return MineJob(mine: score.target, market: score.market);
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
  const creditsBuffer = 20000;
  final remainingUnits = good.unitsRequired - good.unitsFulfilled;
  // TODO(eseidel): 100000 is an arbitrary minimum we should remove!
  return max(100000, maxUnitPrice * remainingUnits + creditsBuffer);
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
  // We could put some "total value" on the idea of the gate being open
  // and change that over time to encourage building it sooner.
  // For now we're just hard-coding a price for each needed good.
  final maxPurchasePrice = {
    TradeSymbol.FAB_MATS: 1800,
    TradeSymbol.ADVANCED_CIRCUITRY: 18000,
  };

  for (final material in construction.materials) {
    final unitsNeeded = remainingUnitsNeeded(material.tradeSymbol);
    if (unitsNeeded > 0) {
      yield SellOpp.fromConstruction(
        waypointSymbol: construction.waypointSymbol,
        tradeSymbol: material.tradeSymbol,
        price: maxPurchasePrice[material.tradeSymbol]!,
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
    Behavior.explorer,
  ];
  final idleHaulerStates = behaviorCache.states
      .where((s) => haulerSymbols.contains(s.shipSymbol))
      .where((s) => idleBehaviors.contains(s.behavior))
      .toList();
  return idleHaulerStates.map((s) => s.shipSymbol).toList();
}

/// Compute the correct squad for the given [ship].
@visibleForTesting
MiningSquad? findSquadForShip(List<MiningSquad> squads, Ship ship) {
  if (squads.isEmpty) {
    return null;
  }
  // Score all squads based on how much they need this type of ship?
  // Add to the squad with the lowest score?
  final fleetRole = ship.fleetRole;
  // Hack for now to restrict to miners / surveyors.
  if (fleetRole != FleetRole.miner && fleetRole != FleetRole.surveyor) {
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
Future<List<MiningSquad>> assignShipsToSquads(
  WaypointCache waypointCache,
  MarketListingCache marketListings,
  ShipCache shipCache, {
  required SystemSymbol systemSymbol,
}) async {
  // Look at the top N mining scores.
  final scores = (await evaluateWaypointsForMining(
    waypointCache,
    marketListings,
    systemSymbol,
  ))
      .where((m) => m.marketTradesAllProducedGoods)
      .where((m) => m.score < 80)
      .toList();
  // Divide our current ships into N squads.
  final squads = List.generate(scores.length, (index) {
    final score = scores[index];
    final job = MineJob(mine: score.mine, market: score.market);
    return MiningSquad(job);
  });
  // Go through and assign all ships to squads.
  for (final ship in shipCache.ships) {
    findSquadForShip(squads, ship)?.ships.add(ship);
  }
  return squads;
}
