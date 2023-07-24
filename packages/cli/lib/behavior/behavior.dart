import 'package:cli/api.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/trading.dart';

/// Enum to specify which behavior the ship should follow.
enum Behavior {
  /// Go to a shipyard and buy a ship.
  buyShip,

  /// Trade for profit.
  trader,

  /// Mine asteroids and sell the ore.
  miner,

  /// Idle.
  idle,

  /// Fetch an item, bring it somewhere and wait.
  deliver,

  /// Change mounts on this ship.
  changeMounts,

  /// Explore the universe.
  explorer;

  /// encode the enum as Json.
  String toJson() => name;

  /// decode the enum from Json.
  static Behavior fromJson(String json) =>
      values.firstWhere((b) => b.name == json);
}

/// Class holding the persistent state for a behavior.
// Want this to be lifetime managed in way such that Behavior's can clear it
// as well as that it's auto-cleaned up if not acknowledged by the behavior
// or on error.
// Also want a way for Behavior's to vote that they should not be the current
// behavior for that ship or ship-type for some timeout.
class BehaviorState {
  /// Create a new behavior state.
  BehaviorState(
    this.shipSymbol,
    this.behavior, {
    this.deal,
    this.routePlan,
    this.mountToAdd,
  });

  /// Create a new behavior state from JSON.
  factory BehaviorState.fromJson(Map<String, dynamic> json) {
    final behavior = Behavior.fromJson(json['behavior'] as String);
    final shipSymbol = ShipSymbol.fromJson(json['shipSymbol'] as String);
    final deal = json['deal'] == null
        ? null
        : CostedDeal.fromJson(json['deal'] as Map<String, dynamic>);
    final routePlan = json['routePlan'] == null
        ? null
        : RoutePlan.fromJson(json['routePlan'] as Map<String, dynamic>);
    final mountToAdd = json['mountToAdd'] == null
        ? null
        : ShipMountSymbolEnum.fromJson(json['mountToAdd'] as String);
    return BehaviorState(
      shipSymbol,
      behavior,
      deal: deal,
      routePlan: routePlan,
      mountToAdd: mountToAdd,
    );
  }

  /// The symbol of the ship this state is for.
  final ShipSymbol shipSymbol;

  /// The current behavior.
  final Behavior behavior;

  /// Current deal.
  CostedDeal? deal;

  /// Current route plan.
  RoutePlan? routePlan;

  /// Mount to add.
  ShipMountSymbolEnum? mountToAdd;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'behavior': behavior.toJson(),
      'shipSymbol': shipSymbol.toJson(),
      'deal': deal?.toJson(),
      'routePlan': routePlan?.toJson(),
      'mountToAdd': mountToAdd?.toJson(),
    };
  }
}
