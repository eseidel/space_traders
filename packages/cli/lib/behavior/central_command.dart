import 'dart:math';

import 'package:cli/behavior/miner.dart';
import 'package:cli/behavior/mount_from_buy.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
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

  /// How old can explorer data be before we refresh it?
  Duration _maxAgeForExplorerData = const Duration(days: 3);

  /// The next planned ship buy job.
  /// This is the start of an imagined job queue system, whereby we pre-populate
  /// BehaviorStates with jobs when handing them out to ships.
  ShipBuyJob? _nextShipBuyJob;

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
    // This should depend on phase and ship type?
    return 7;
  }

  /// Data older than this will be refreshed by explorers.
  /// Explorers will shorten this time if they run out of places to explore.
  Duration get maxAgeForExplorerData => _maxAgeForExplorerData;

  /// Shorten the max age for explorer data.
  Duration shortenMaxAgeForExplorerData() => _maxAgeForExplorerData ~/= 2;

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
    final shipCount = _shipCache.ships.length;

    final behaviors = {
      ShipRole.COMMAND: [
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
        if (ship.canMine) Behavior.miner,
        if (!ship.canMine && ship.hasSurveyor) Behavior.surveyor,
        Behavior.idle,
      ],
      ShipRole.SATELLITE: [Behavior.explorer],
    }[ship.registration.role];
    if (behaviors != null) {
      for (final behavior in behaviors) {
        if (!_behaviorCache.isBehaviorDisabledForShip(ship, behavior)) {
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

  // This feels wrong.
  /// Load or create the right behavior state for [ship].
  Future<BehaviorState> loadBehaviorState(Ship ship, int credits) async {
    final shipSymbol = ship.shipSymbol;
    final state = _behaviorCache.getBehavior(shipSymbol);
    if (state == null) {
      final newState = getJobForShip(ship, credits);
      // Important to set the state in the cache immediately, so that if we
      // yield, other ships can see what we're doing.
      _behaviorCache.setBehavior(shipSymbol, newState);
    }
    return _behaviorCache.getBehavior(shipSymbol)!;
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

    final inProgress = _behaviorCache.dealsInProgress().toList();
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
  Iterable<SystemSymbol> otherTraderSystems(ShipSymbol thisShipSymbol) =>
      _otherSystemsWithBehavior(thisShipSymbol, Behavior.trader);

  Future<void> _queueMountRequests(
    Caches caches,
  ) async {
    for (final ship in _shipCache.ships) {
      if (_mountRequests.any((m) => m.shipSymbol == ship.shipSymbol)) {
        return;
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

  /// Give central planning a chance to advance.
  Future<void> advanceCentralPlanning(Api api, Caches caches) async {
    _nextShipBuyJob ??= await _computeNextShipBuyJob(api, caches);
    await _queueMountRequests(caches);
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

  /// Computes the next ship buy job.
  Future<ShipBuyJob?> _computeNextShipBuyJob(Api api, Caches caches) async {
    final agentCache = caches.agent;
    final waypointCache = caches.waypoints;
    final shipCount = _shipCache.ships.length;
    if (shipCount > 80) {
      return null;
    }
    // if our ship count is < 80, return an ore hound.
    final hqSystem = agentCache.headquartersSymbol.systemSymbol;
    final hqWaypoints = await waypointCache.waypointsInSystem(hqSystem);
    final shipyard = hqWaypoints.firstWhere((w) => w.hasShipyard);
    final recentPrice = caches.shipyardPrices.recentPurchasePrice(
      shipType: ShipType.ORE_HOUND,
      shipyardSymbol: shipyard.waypointSymbol,
    );
    if (recentPrice == null) {
      return null;
    }
    return ShipBuyJob(
      shipType: ShipType.ORE_HOUND,
      shipyardSymbol: shipyard.waypointSymbol,
      minCreditsNeeded: (recentPrice * 1.05).toInt(),
    );
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
    // Are there any other ships actively buying mounts?
    if (_behaviorCache.states.any(
      (s) => s.behavior == Behavior.mountFromBuy,
    )) {
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

  /// How many haulers do we have?
  int get numberOfHaulers =>
      _shipCache.frameCounts[ShipFrameSymbolEnum.LIGHT_FREIGHTER] ?? 0;

  /// The minimum credits we should have to buy a new ship.
  int get minimumCreditsForTrading => numberOfHaulers * 10000;

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
