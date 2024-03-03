import 'package:cli/cache/ship_snapshot.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/printing.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

@immutable
class _ShipTimeout {
  const _ShipTimeout(this.shipSymbol, this.behavior, this.timeout);

  final ShipSymbol shipSymbol;
  final Behavior behavior;
  final DateTime timeout;
}

/// A class to manage behavior timeouts.
class BehaviorTimeouts {
  /// Used for temporarily disabling a ship, not persisted.
  final List<_ShipTimeout> _shipTimeouts = [];

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

  /// Disable the given behavior for [ship] for [duration].
  Future<void> disableBehaviorForShip(
    Database db,
    Ship ship,
    String why,
    Duration duration,
  ) async {
    final shipSymbol = ship.shipSymbol;
    final currentState = await db.behaviorStateBySymbol(shipSymbol);
    final behavior = currentState?.behavior;
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
      await db.deleteBehaviorState(shipSymbol);
    } else {
      shipInfo(ship, 'Not deleting ${currentState.behavior} for $shipSymbol.');
    }

    final expiration = DateTime.timestamp().add(duration);
    _shipTimeouts.add(_ShipTimeout(ship.shipSymbol, behavior, expiration));
  }
}

/// A snapshot of the behavior states
class BehaviorSnapshot {
  /// Create a new behavior snapshot.
  BehaviorSnapshot(this.states);

  /// The behavior states.
  final List<BehaviorState> states;

  /// Load the behavior snapshot from the database.
  static Future<BehaviorSnapshot> load(Database db) async {
    final states = await db.allBehaviorStates();
    return BehaviorSnapshot(states.toList());
  }

  /// Get the behavior state for the given ship.
  BehaviorState? stateForShip(ShipSymbol shipSymbol) {
    return states.firstWhereOrNull((s) => s.shipSymbol == shipSymbol);
  }

  /// Get the behavior state for the given ship.
  BehaviorState? operator [](ShipSymbol shipSymbol) => stateForShip(shipSymbol);

  /// Returns all deals in progress.
  Iterable<CostedDeal> dealsInProgress() sync* {
    for (final state in states) {
      final deal = state.deal;
      if (deal != null) {
        yield deal;
      }
    }
  }

  /// Returns the ship symbols for all idle haulers.
// TODO(eseidel): This should be a db query.
  List<ShipSymbol> idleHaulerSymbols(
    ShipSnapshot shipCache,
  ) {
    final haulerSymbols =
        shipCache.ships.where((s) => s.isHauler).map((s) => s.shipSymbol);
    final idleBehaviors = [
      Behavior.idle,
      Behavior.charter,
    ];
    final idleHaulerStates = states
        .where((s) => haulerSymbols.contains(s.shipSymbol))
        .where((s) => idleBehaviors.contains(s.behavior))
        .toList();
    return idleHaulerStates.map((s) => s.shipSymbol).toList();
  }
}

/// Get the behavior state for the given ship, or call [ifAbsent] to create it
/// if it doesn't exist.
Future<BehaviorState> createBehaviorIfAbsent(
  Database db,
  ShipSymbol shipSymbol,
  Future<BehaviorState> Function() ifAbsent,
) async {
  final currentState = await db.behaviorStateBySymbol(shipSymbol);
  if (currentState != null) {
    return currentState;
  }
  final newState = await ifAbsent();
  await db.setBehaviorState(newState);
  return newState;
}
