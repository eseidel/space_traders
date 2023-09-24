import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Enum to specify which behavior the ship should follow.
enum Behavior {
  /// Go to a shipyard and buy a ship.
  buyShip,

  /// Trade for profit.
  trader,

  /// Mine asteroids and sell the ore.
  miner,

  /// Survey indefinitely.
  surveyor,

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
    this.buyJob,
    this.shipBuyJob,
    this.deliverJob,
    this.jobIndex = 0,
  }) : isComplete = false;

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
    final buyJob = json['buyJob'] == null
        ? null
        : BuyJob.fromJson(json['buyJob'] as Map<String, dynamic>);
    final deliverJob = json['deliverJob'] == null
        ? null
        : DeliverJob.fromJson(json['deliverJob'] as Map<String, dynamic>);
    final shipBuyJob = json['shipBuyJob'] == null
        ? null
        : ShipBuyJob.fromJson(json['shipBuyJob'] as Map<String, dynamic>);
    final jobIndex = json['jobIndex'] as int? ?? 0;
    return BehaviorState(
      shipSymbol,
      behavior,
      deal: deal,
      routePlan: routePlan,
      mountToAdd: mountToAdd,
      buyJob: buyJob,
      deliverJob: deliverJob,
      shipBuyJob: shipBuyJob,
      jobIndex: jobIndex,
    );
  }

  /// The symbol of the ship this state is for.
  final ShipSymbol shipSymbol;

  /// The current behavior.
  final Behavior behavior;

  /// Used for compound jobs (Deliver is the only one so far).
  int jobIndex;

  /// Current deal.
  CostedDeal? deal;

  /// Current route plan.
  RoutePlan? routePlan;

  /// Used by Behavior.deliver for buying (but not selling) items.
  BuyJob? buyJob;

  /// Used by Behavior.deliver for delivering items.
  DeliverJob? deliverJob;

  /// Mount to add.
  ShipMountSymbolEnum? mountToAdd;

  /// Used by Behavior.buyShip for buying a ship.
  ShipBuyJob? shipBuyJob;

  /// This behavior is complete.
  /// Never written to disk (instead the behavior state is deleted).
  bool isComplete;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'behavior': behavior.toJson(),
      'shipSymbol': shipSymbol.toJson(),
      'deal': deal?.toJson(),
      'routePlan': routePlan?.toJson(),
      'mountToAdd': mountToAdd?.toJson(),
      'buyJob': buyJob?.toJson(),
      'deliverJob': deliverJob?.toJson(),
      'shipBuyJob': shipBuyJob?.toJson(),
      'jobIndex': jobIndex,
    };
  }
}

/// A job to buy a given item.
@immutable
class BuyJob {
  /// Create a new buy job.
  const BuyJob({
    required this.tradeSymbol,
    required this.units,
    required this.buyLocation,
  });

  /// Create a new buy job from JSON.
  factory BuyJob.fromJson(Map<String, dynamic> json) {
    final tradeSymbol = TradeSymbol.fromJson(json['tradeSymbol'] as String)!;
    final units = json['units'] as int;
    final buyLocation = WaypointSymbol.fromJson(json['buyLocation'] as String);
    return BuyJob(
      tradeSymbol: tradeSymbol,
      units: units,
      buyLocation: buyLocation,
    );
  }

  /// The item to buy.
  final TradeSymbol tradeSymbol;

  /// The number of units to buy.
  final int units;

  /// Where we plan to buy from.
  final WaypointSymbol buyLocation;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tradeSymbol': tradeSymbol.toJson(),
      'units': units,
      'buyLocation': buyLocation.toJson(),
    };
  }
}

/// Deliver tradeSymbol to waypointSymbol and wait until they're all gone.
class DeliverJob {
  /// Create a new deliver job.
  DeliverJob({
    required this.tradeSymbol,
    required this.waypointSymbol,
  });

  /// Create a new deliver job from JSON.
  factory DeliverJob.fromJson(Map<String, dynamic> json) {
    final tradeSymbol = TradeSymbol.fromJson(json['tradeSymbol'] as String)!;
    final waypointSymbol =
        WaypointSymbol.fromJson(json['waypointSymbol'] as String);
    return DeliverJob(
      tradeSymbol: tradeSymbol,
      waypointSymbol: waypointSymbol,
    );
  }

  /// The item to deliver (and wait until empty).
  final TradeSymbol tradeSymbol;

  /// Where we plan to deliver to.
  final WaypointSymbol waypointSymbol;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tradeSymbol': tradeSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
    };
  }
}

/// Job to buy a ship.
class ShipBuyJob {
  /// Create a new ship buy job.
  ShipBuyJob({
    required this.shipType,
    required this.shipyardSymbol,
    required this.minCreditsNeeded,
  });

  /// Create a new ship buy job from JSON.
  factory ShipBuyJob.fromJson(Map<String, dynamic> json) {
    final shipType = ShipType.fromJson(json['shipType'] as String)!;
    final shipyardSymbol =
        WaypointSymbol.fromJson(json['shipyardSymbol'] as String);
    final minCreditsNeeded = json['minCreditsNeeded'] as int;
    return ShipBuyJob(
      shipType: shipType,
      shipyardSymbol: shipyardSymbol,
      minCreditsNeeded: minCreditsNeeded,
    );
  }

  /// The type of ship to buy.
  final ShipType shipType;

  /// The waypoint to buy the ship at.
  final WaypointSymbol shipyardSymbol;

  /// Number of credits we expect to need to do this buy.
  final int minCreditsNeeded;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shipType': shipType.toJson(),
      'shipyardSymbol': shipyardSymbol.toJson(),
      'minCreditsNeeded': minCreditsNeeded,
    };
  }
}
