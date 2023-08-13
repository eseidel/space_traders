import 'package:cli/behavior/deliver.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/trading.dart';
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
    this.deliverJob,
    this.jobIndex = 0,
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
    final buyJob = json['buyJob'] == null
        ? null
        : BuyJob.fromJson(json['buyJob'] as Map<String, dynamic>);
    final deliverJob = json['deliverJob'] == null
        ? null
        : DeliverJob.fromJson(json['deliverJob'] as Map<String, dynamic>);
    final jobIndex = json['jobIndex'] as int? ?? 0;
    return BehaviorState(
      shipSymbol,
      behavior,
      deal: deal,
      routePlan: routePlan,
      mountToAdd: mountToAdd,
      buyJob: buyJob,
      deliverJob: deliverJob,
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
      'jobIndex': jobIndex,
    };
  }
}

/// Disable behavior for this ship or all ships?
enum DisableBehavior {
  /// Disable behavior for this ship only.
  thisShip,

  /// Disable behavior for all ships.
  allShips,
}

/// Exception thrown from a Job.
@immutable
class JobException implements Exception {
  /// Create a new job exception.
  const JobException(
    this.message,
    this.timeout, {
    this.disable = DisableBehavior.thisShip,
    this.explicitBehavior,
  });

  /// Why did the job error?
  final String message;

  /// How long should the calling behavior be disabled
  final Duration timeout;

  /// Should the behavior be disabled for this ship or all ships?
  final DisableBehavior disable;

  /// Was this exception thrown in a behavior other than the current one?
  final Behavior? explicitBehavior;

  @override
  String toString() => 'JobException: $message, timeout: $timeout, '
      'disable: $disable, explicitBehavior: $explicitBehavior';

  @override
  bool operator ==(Object other) =>
      other is JobException &&
      message == other.message &&
      timeout == other.timeout &&
      disable == other.disable &&
      explicitBehavior == other.explicitBehavior;

  @override
  int get hashCode =>
      message.hashCode ^
      timeout.hashCode ^
      disable.hashCode ^
      explicitBehavior.hashCode;
}

/// Exception thrown from a Job if the condition is not met.
void jobAssert(
  // ignore: avoid_positional_boolean_parameters
  bool condition,
  String message,
  Duration timeout, {
  DisableBehavior disable = DisableBehavior.thisShip,
}) {
  if (!condition) {
    throw JobException(
      message,
      timeout,
      disable: disable,
    );
  }
}

/// Exception thrown from a Job if the condition is not met.
T assertNotNull<T>(
  T? value,
  String message,
  Duration timeout, {
  DisableBehavior disable = DisableBehavior.thisShip,
}) {
  if (value == null) {
    throw JobException(
      message,
      timeout,
      disable: disable,
    );
  }
  return value;
}
