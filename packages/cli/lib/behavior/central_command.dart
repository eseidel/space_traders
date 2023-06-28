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

import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

/// Central command for the fleet.
class CentralCommand {
  /// Create a new central command.
  CentralCommand(BehaviorCache behaviorCache, ShipCache shipCache)
      : _behaviorCache = behaviorCache,
        _shipCache = shipCache;

  final Map<Behavior, DateTime> _behaviorTimeouts = {};

  final BehaviorCache _behaviorCache;
  final ShipCache _shipCache;

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

  /// Check if the given behavior is enabled.
  bool isEnabled(Behavior behavior) {
    final expiration = _behaviorTimeouts[behavior];
    if (expiration == null) {
      return true;
    }
    if (DateTime.now().isAfter(expiration)) {
      _behaviorTimeouts.remove(behavior);
      return true;
    }
    return false;
  }

// Consider having a config file like:
// https://gist.github.com/whyando/fed97534173437d8234be10ac03595e0
// instead of having this dynamic behavior function.
// At the top of the file because I change this so often.
  /// What behavior should the given ship be doing?
  Behavior behaviorFor(
    BehaviorCache behaviorManager,
    Ship ship,
  ) {
    final disableBehaviors = <Behavior>[
      // Behavior.buyShip,
      // Behavior.trader,
      // Behavior.miner,
      // Behavior.idle,
      // Behavior.explorer,
    ];

    final behaviors = {
      ShipRole.COMMAND: [Behavior.buyShip, Behavior.trader, Behavior.miner],
      // Can't have more than one contract trader on small/expensive contracts
      // or we'll overbuy.
      ShipRole.HAULER: [
        Behavior.trader,
      ],
      ShipRole.EXCAVATOR: [Behavior.miner],
      ShipRole.SATELLITE: [Behavior.explorer],
    }[ship.registration.role];
    if (behaviors != null) {
      for (final behavior in behaviors) {
        if (disableBehaviors.contains(behavior)) {
          continue;
        }
        if (isEnabled(behavior)) {
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
  Future<void> disableBehavior(
    Ship ship,
    Behavior behavior,
    String why,
    Duration timeout,
  ) async {
    await _behaviorCache.deleteBehavior(ship.symbol);

    shipWarn(
      ship,
      '$why Disabling $behavior for ${approximateDuration(timeout)}.',
    );

    final expiration = DateTime.now().add(timeout);
    _behaviorTimeouts[behavior] = expiration;
  }

  /// Complete the current behavior for the given ship.
  Future<void> completeBehavior(String shipSymbol) async {
    return _behaviorCache.deleteBehavior(shipSymbol);
  }

  /// Set the destination for the given ship.
  Future<void> setDestination(Ship ship, String destinationSymbol) async {
    final state = _behaviorCache.getBehavior(ship.symbol)!
      ..destination = destinationSymbol;
    await _behaviorCache.setBehavior(ship.symbol, state);
  }

  /// Get the current destination for the given ship.
  String? currentDestination(Ship ship) {
    final state = _behaviorCache.getBehavior(ship.symbol);
    return state?.destination;
  }

  /// The [ship] has reached its destination.
  Future<void> reachedDestination(Ship ship) async {
    final state = _behaviorCache.getBehavior(ship.symbol)!..destination = null;
    await _behaviorCache.setBehavior(ship.symbol, state);
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
      final behavior = behaviorFor(_behaviorCache, ship);
      final newState = BehaviorState(
        ship.symbol,
        behavior,
      );
      await _behaviorCache.setBehavior(ship.symbol, newState);
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
    await _behaviorCache.setBehavior(shipSymbol, state);
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

  /// Returns true if contract trading is enabled.
  /// We will only accept and start new contracts when this is true.
  /// We will continue to deliver current contract deals even if this is false,
  /// but will not start new deals involving contracts.
  bool get isContractTradingEnabled => false;

  Iterable<SellOpp> _contractSellOpps(
    AgentCache agentCache,
    ContractCache contractCache,
  ) sync* {
    for (final contract in affordableContracts(agentCache, contractCache)) {
      for (final good in contract.terms.deliver) {
        yield SellOpp(
          marketSymbol: good.destinationSymbol,
          tradeSymbol: good.tradeSymbol,
          isContractDelivery: true,
          price: _maxWorthwhileUnitPurchasePrice(contract, good),
          maxUnits: remainingUnitsNeededForContract(contract, good.tradeSymbol),
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
    WaypointCache waypointCache,
    MarketCache marketCache,
    Ship ship, {
    required int maxJumps,
    required int maxTotalOutlay,
    required int availableSpace,
  }) async {
    final inProgress = _dealsInProgress().toList();
    // Avoid having two ships working on the same deal since by the time the
    // second one gets there the prices will have changed.
    bool filter(CostedDeal deal) {
      return inProgress.any(
        (d) =>
            d.deal.sourceSymbol != deal.deal.sourceSymbol ||
            d.deal.tradeSymbol != deal.deal.tradeSymbol,
      );
    }

    /// This should decide if contract trading is enabled, and if it is
    /// include extra SellOpps for the contract goods.
    final contractSellOpps = isContractTradingEnabled
        ? _contractSellOpps(agentCache, contractCache).toList()
        : null;

    final maybeDeal = await findDealFor(
      marketPrices,
      systemsCache,
      waypointCache,
      marketCache,
      ship,
      maxJumps: maxJumps,
      maxTotalOutlay: maxTotalOutlay,
      availableSpace: ship.availableSpace,
      extraSellOpps: contractSellOpps,
      filter: filter,
    );
    return maybeDeal;
  }

  /// Returns all systems containing explorers or explorer destinations.
  Iterable<String> otherExplorerSystems(String thisShipSymbol) sync* {
    for (final state in _behaviorCache.states) {
      if (state.shipSymbol == thisShipSymbol) {
        continue;
      }
      if (state.behavior == Behavior.explorer) {
        final destination = state.destination;
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
  ShipType? shipTypeToBuy({int? randomSeed}) {
    // We should buy a new ship when:
    // - We have request capacity to spare
    // - We have money to spare.
    // - We don't have better uses for the money (e.g. trading or modules)

    // We should buy ships based on earnings of that ship type over the last
    // N hours?

    final isEarlyGame = _shipCache.ships.length < 10;
    if (isEarlyGame) {
      return ShipType.ORE_HOUND;
    }

    final random = Random(randomSeed);
    final targetCounts = {
      ShipType.ORE_HOUND: 30,
      ShipType.PROBE: 10,
      ShipType.LIGHT_HAULER: 20,
    };
    final typesToBuy = targetCounts.keys
        .where(
          (shipType) => _countOfTypeInFleet(shipType) < targetCounts[shipType]!,
        )
        .toList();
    if (typesToBuy.isEmpty) {
      return null;
    }
    return typesToBuy[random.nextInt(typesToBuy.length)];
  }

  /// Computes the number of units needed to fulfill the given [contract].
  /// It should exclude units already spoken for by other ships, but doesn't
  /// yet.
  int remainingUnitsNeededForContract(Contract contract, String tradeSymbol) {
    // TODO(eseidel): This has the potential of racing with multiple ships.
    // This should look at the deals other ships are working on and subtract
    // those from what remains in the contract.
    final neededGood = contract.goodNeeded(tradeSymbol);
    return neededGood!.unitsRequired - neededGood.unitsFulfilled;
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
      .where((c) => _minimumFloatRequired(c) < credits);
}
