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
class BehaviorState {
  /// Create a new behavior state.
  BehaviorState(this.behavior);

  /// The current behavior.
  final Behavior behavior;

  /// The current route.
  Route? route;
}
