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

import 'package:cli/behavior/behavior.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

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
      Behavior.contractTrader,
      // Behavior.arbitrageTrader,
      // Behavior.miner,
      // Behavior.idle,
      // Behavior.explorer,
    ];

    final behaviors = {
      ShipRole.COMMAND: [
        Behavior.buyShip,
        Behavior.contractTrader,
        Behavior.arbitrageTrader,
        Behavior.miner
      ],
      // Can't have more than one contract trader on small/expensive contracts
      // or we'll overbuy.
      ShipRole.HAULER: [
        Behavior.contractTrader,
        Behavior.arbitrageTrader,
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
}
