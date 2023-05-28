import 'package:space_traders_cli/data_store.dart';

/// Enum to specify which behavior the ship should follow.
enum Behavior {
  /// Trade to fulfill the current contract.
  contractTrader,

  /// Trade for profit.
  arbitrageTrader,

  /// Mine asteroids and sell the ore.
  miner,

  /// Explore the universe.
  explorer;

  /// encode the enum as Json.
  String toJson() => name;

  /// decode the enum from Json.
  static Behavior fromJson(String json) {
    return values.firstWhere((b) => b.name == json);
  }
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
    final destination = json['destination'] as String?;
    return BehaviorState(
      Behavior.values.firstWhere((b) => b.toString() == behavior),
    )..destination = destination;
  }

  /// The current behavior.
  final Behavior behavior;

  /// Current navigation destination.
  String? destination;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'behavior': behavior.toString(),
      'destination': destination,
    };
  }
}

/// Function to set Behavior per ship.
typedef BehaviorPolicy = Behavior Function(BehaviorManager, String);

/// Class to allow managemnet of BehaviorState.
class BehaviorManager {
  /// Create a new behavior manager.
  BehaviorManager._(this._db, this._policy, this._behaviorTimeouts);

  /// The database.
  final DataStore _db;
  final BehaviorPolicy _policy;
  final Map<Behavior, DateTime> _behaviorTimeouts;

  /// Load the behavior manager.
  static Future<BehaviorManager> load(
    DataStore db,
    BehaviorPolicy policy,
  ) async {
    final behaviorTimeouts = await loadBehaviorTimeouts(db) ?? {};
    return BehaviorManager._(
      db,
      policy,
      behaviorTimeouts,
    );
  }

  /// Get the behavior state for the given ship.
  Future<BehaviorState> getBehavior(String shipId) async {
    return await loadBehaviorState(_db, shipId) ??
        BehaviorState(_policy(this, shipId));
  }

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

  /// Disable the given behavior for an hour.
  Future<void> disableBehavior(Behavior behavior) {
    final expiration = DateTime.now().add(const Duration(hours: 1));
    _behaviorTimeouts[behavior] = expiration;
    return saveBehaviorTimeouts(
      _db,
      _behaviorTimeouts,
    );
  }

  /// Set the behavior state for the given ship.
  Future<void> setBehavior(
    String shipId,
    BehaviorState behaviorState,
  ) async {
    await saveBehaviorState(_db, shipId, behaviorState);
  }
}
