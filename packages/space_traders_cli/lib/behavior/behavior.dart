import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/route.dart';

/// Enum to specify which behavior the ship should follow.
enum Behavior {
  /// Trade to fulfill the current contract.
  contractTrader,

  /// Trade for profit.
  arbitrageTrader,

  /// Mine asteroids and sell the ore.
  miner,

  /// Explore the universe.
  explorer,
}

/// Class holding the persistent state for a behavior.
// Want this to be lifetime managed in way such that Behavior's can clear it
// as well as that it's auto-cleaned up if not acknowledged by the behavior
// or on error.
// Also want a way for Behavior's to vote that they should not be the current
// behavior for that ship or ship-type for some timeout.
class BehaviorState {
  /// Create a new behavior state.
  BehaviorState(this.behavior);

  /// Create a new behavior state from JSON.
  factory BehaviorState.fromJson(Map<String, dynamic> json) {
    final behavior = json['behavior'] as String;
    final route = json['route'] as Map<String, dynamic>?;
    return BehaviorState(
      Behavior.values.firstWhere((b) => b.toString() == behavior),
    )..route = route == null ? null : Route.fromJson(route);
  }

  /// The current behavior.
  final Behavior behavior;

  /// The current route.
  Route? route;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'behavior': behavior.toString(),
      'route': route?.toJson(),
    };
  }
}

/// Class to allow managemnet of BehaviorState.
class BehaviorManager {
  /// Create a new behavior manager.
  BehaviorManager(this._db, this._policy);

  /// The database.
  final DataStore _db;
  final Behavior Function(String shipId) _policy;

  /// Get the behavior state for the given ship.
  Future<BehaviorState> getBehavior(String shipId) async {
    return await loadBehaviorState(_db, shipId) ??
        BehaviorState(_policy(shipId));
  }

  /// Set the behavior state for the given ship.
  Future<void> setBehavior(
    String shipId,
    BehaviorState behaviorState,
  ) async {
    await saveBehaviorState(_db, shipId, behaviorState);
  }
}
