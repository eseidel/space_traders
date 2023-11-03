import 'dart:math';

import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/mine_scores.dart';
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
    return 7;
  }

  /// Data older than this will be refreshed by explorers.
  /// Explorers will shorten this time if they run out of places to explore.
  Duration get maxAgeForExplorerData => _maxAgeForExplorerData;

  /// Shorten the max age for explorer data.
  Duration shortenMaxAgeForExplorerData() => _maxAgeForExplorerData ~/= 2;

  /// Returns the mining squads for the fleet.
  Iterable<MiningSquad> get miningSquads {
    return _shipCache.ships
        .where((s) => s.isMiner)
        .slices(5)
        .map(MiningSquad.new);
  }

  /// Returns the mining squad for the given [ship].
  MiningSquad? squadForShip(Ship ship) {
    return miningSquads.firstWhereOrNull((s) => s.contains(ship));
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
        // Mostly to test the logic out.
        Behavior.siphoner,
        // Early on the command ship makes about 5c/s vs. ore hounds making
        // 6c/s. It's a better surveyor than miner. Especially when enabling
        // mining drones.
        // if (shipCount > 3 && shipCount < 10) Behavior.surveyor,
        Behavior.miner,
      ],
      FleetRole.trader: [
        Behavior.trader,
        // Would rather have Haulers idle, than explore, at least early game.
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

    final inProgress = _behaviorCache.dealsInProgress().toList();
    // Avoid having two ships working on the same deal since by the time the
    // second one gets there the prices will have changed.
    // Note this does not check destination, so should still allow two
    // ships to work on the same contract.
    bool filter(CostedDeal deal) {
      return inProgress.every(
        (d) =>
            // Deals need to differ in their source *or* their trade symbol
            // for us to consider them.
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
    final maybeDeal = findDealsFor(
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
    ).firstOrNull;
    return maybeDeal;
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

  /// Give central planning a chance to advance.
  Future<void> advanceCentralPlanning(Api api, Caches caches) async {
    _nextShipBuyJob ??= await _computeNextShipBuyJob(api, caches);
    updateAvailableMounts(caches.marketPrices);
    await _queueMountRequests(caches);
    // We'll assume that if all the ships are in the same system we've
    // not yet constructed our jump gate.
    if (!_haveEscapedStartingSystem) {
      final systemSymbols = Set<SystemSymbol>.from(
        _shipCache.ships.map((s) => s.nav.systemSymbolObject),
      );
      _haveEscapedStartingSystem = systemSymbols.length > 1;
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
    bool shouldBuy(ShipType shipType, int count) {
      final typeCount =
          _shipCache.countOfType(caches.static.shipyardShips, shipType) ?? 0;
      return caches.shipyardPrices.havePriceFor(shipType) && typeCount < count;
    }

    // These numbers should be based on squad sizes so that we always have
    // full squads.
    if (shouldBuy(ShipType.ORE_HOUND, 10)) {
      return _findBestPlaceToBuy(caches, ShipType.ORE_HOUND);
    } else if (shouldBuy(ShipType.MINING_DRONE, 10)) {
      return _findBestPlaceToBuy(caches, ShipType.MINING_DRONE);
    } else if (shouldBuy(ShipType.SIPHON_DRONE, 10)) {
      return _findBestPlaceToBuy(caches, ShipType.SIPHON_DRONE);
    } else if (shouldBuy(ShipType.SURVEYOR, 10)) {
      return _findBestPlaceToBuy(caches, ShipType.SURVEYOR);
    } else if (shouldBuy(ShipType.LIGHT_HAULER, 6)) {
      return _findBestPlaceToBuy(caches, ShipType.LIGHT_HAULER);
    } else if (shouldBuy(ShipType.HEAVY_FREIGHTER, 10)) {
      return _findBestPlaceToBuy(caches, ShipType.HEAVY_FREIGHTER);
    } else if (shouldBuy(ShipType.PROBE, 3)) {
      return _findBestPlaceToBuy(caches, ShipType.PROBE);
    }
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
    if (credits < buyJob.minCreditsNeeded) {
      return false;
    }
    // Is this ship within the same system or the command ship?
    if (ship.systemSymbol != buyJob.shipyardSymbol.systemSymbol &&
        !ship.isCommand) {
      return false;
    }
    return true;
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
  // TODO(eseidel): call from or merge into getJobForShip.
  Future<MineJob?> mineJobForShip(
    WaypointCache waypointCache,
    MarketListingCache marketListings,
    AgentCache agentCache,
    Ship ship,
  ) async {
    final hq = agentCache.agent.headquartersSymbol;
    final score = (await evaluateWaypointsForMining(
      waypointCache,
      marketListings,
      hq.systemSymbol,
    ))
        // TODO(eseidel): Add dynamic planning of where to send squads.
        // This is just a hack to move us off the first mine for now.
        .skip(1)
        .firstWhereOrNull((m) => m.marketTradesAllProducedGoods);
    if (score == null) {
      return null;
    }
    return MineJob(mine: score.mine, market: score.market);
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
