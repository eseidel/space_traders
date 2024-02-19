import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
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
    BehaviorCache behaviorCache,
    Ship ship,
    String why,
    Duration duration,
  ) async {
    final shipSymbol = ship.shipSymbol;
    final currentState = behaviorCache.getBehavior(shipSymbol);
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
      await behaviorCache.deleteBehavior(shipSymbol);
    } else {
      shipInfo(ship, 'Not deleting ${currentState.behavior} for $shipSymbol.');
    }

    final expiration = DateTime.timestamp().add(duration);
    _shipTimeouts.add(_ShipTimeout(ship.shipSymbol, behavior, expiration));
  }
}

/// A class to manage the behavior cache.
class BehaviorCache {
  /// Create a new behavior cache.
  BehaviorCache(Iterable<BehaviorState> states, Database db)
      : _stateByShipSymbol = Map.fromEntries(
          states.map((state) => MapEntry(state.shipSymbol, state)),
        ),
        _db = db;

  /// Load the cache from a file.
  static Future<BehaviorCache> load(Database db) async {
    final states = await db.allBehaviorStates();
    return BehaviorCache(states, db);
  }

  final Database _db;
  final Map<ShipSymbol, BehaviorState> _stateByShipSymbol;

  /// Get the list of all behavior states.
  List<BehaviorState> get states => _stateByShipSymbol.values.toList();

  /// Get the behavior state for the given ship.
  BehaviorState? getBehavior(ShipSymbol shipSymbol) =>
      _stateByShipSymbol[shipSymbol];

  /// Delete the behavior state for the given ship.
  Future<void> deleteBehavior(ShipSymbol shipSymbol) async {
    await _db.deleteBehaviorState(shipSymbol);
    _stateByShipSymbol.remove(shipSymbol);
  }

  /// Set the behavior state for the given ship.
  Future<void> setBehavior(
    ShipSymbol shipSymbol,
    BehaviorState behaviorState,
  ) async {
    await _db.setBehaviorState(behaviorState);
    _stateByShipSymbol[shipSymbol] = behaviorState;
  }

  /// Get the behavior state for the given ship, or call [ifAbsent] to create it
  /// if it doesn't exist.
  Future<BehaviorState> putIfAbsent(
    ShipSymbol shipSymbol,
    Future<BehaviorState> Function() ifAbsent,
  ) async {
    final currentState = getBehavior(shipSymbol);
    if (currentState != null) {
      return currentState;
    }
    final newState = await ifAbsent();
    await setBehavior(shipSymbol, newState);
    return newState;
  }
}
