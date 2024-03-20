import 'package:collection/collection.dart';
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

  /// Siphon gas giants and sell the hydrocarbons.
  siphoner,

  /// Survey indefinitely.
  surveyor,

  /// Idle.
  idle,

  /// A ship set to seed new systems.
  seeder,

  /// pickup goods from miners and sell them
  minerHauler,

  /// Go buy our own mount and mount it.
  mountFromBuy,

  /// Watch prices within a single system.
  systemWatcher,

  /// Chart the universe.
  charter,

  // Scrap the ship.
  scrap;

  /// encode the enum as Json.
  String toJson() => name;

  /// decode the enum from Json.
  static Behavior fromJson(String json) =>
      values.firstWhere((b) => b.name == json);
}

/// Class holding the persistent state for a behavior.
class BehaviorState {
  /// Create a new behavior state.
  BehaviorState(
    this.shipSymbol,
    this.behavior, {
    this.deal,
    this.routePlan,
    this.buyJob,
    this.shipBuyJob,
    this.deliverJob,
    this.pickupJob,
    this.mountJob,
    this.extractionJob,
    this.systemWatcherJob,
    this.jobIndex = 0,
  }) : isComplete = false;

  /// Create a new behavior state from a fallback value.
  @visibleForTesting
  BehaviorState.fallbackValue() : this(const ShipSymbol('S', 1), Behavior.idle);

  /// Create a new behavior state from JSON.
  factory BehaviorState.fromJson(Map<String, dynamic> json) {
    final behavior = Behavior.fromJson(json['behavior'] as String);
    final shipSymbol = ShipSymbol.fromJson(json['shipSymbol'] as String);
    final deal =
        CostedDeal.fromJsonOrNull(json['deal'] as Map<String, dynamic>?);
    final routePlan =
        RoutePlan.fromJsonOrNull(json['routePlan'] as Map<String, dynamic>?);
    final buyJob =
        BuyJob.fromJsonOrNull(json['buyJob'] as Map<String, dynamic>?);
    final deliverJob =
        DeliverJob.fromJsonOrNull(json['deliverJob'] as Map<String, dynamic>?);
    final shipBuyJob =
        ShipBuyJob.fromJsonOrNull(json['shipBuyJob'] as Map<String, dynamic>?);
    final pickupJob =
        PickupJob.fromJsonOrNull(json['pickupJob'] as Map<String, dynamic>?);
    final mountJob =
        MountJob.fromJsonOrNull(json['mountJob'] as Map<String, dynamic>?);
    final extractionJob = ExtractionJob.fromJsonOrNull(
      json['extractionJob'] as Map<String, dynamic>?,
    );
    final systemWatcherJob = SystemWatcherJob.fromJsonOrNull(
      json['systemWatcherJob'] as Map<String, dynamic>?,
    );
    final jobIndex = json['jobIndex'] as int? ?? 0;
    return BehaviorState(
      shipSymbol,
      behavior,
      deal: deal,
      routePlan: routePlan,
      buyJob: buyJob,
      deliverJob: deliverJob,
      shipBuyJob: shipBuyJob,
      pickupJob: pickupJob,
      mountJob: mountJob,
      extractionJob: extractionJob,
      systemWatcherJob: systemWatcherJob,
      jobIndex: jobIndex,
    );
  }

  /// The symbol of the ship this state is for.
  final ShipSymbol shipSymbol;

  /// The current behavior.
  final Behavior behavior;

  /// Used for MultiJobs
  int jobIndex;

  /// Current deal.
  CostedDeal? deal;

  /// Current route plan.
  RoutePlan? routePlan;

  /// Used by Behavior.deliver for buying (but not selling) items.
  BuyJob? buyJob;

  /// Used by Behavior.deliver for delivering items.
  DeliverJob? deliverJob;

  /// Used by Behavior.mountFromDelivery for picking up the mount.
  PickupJob? pickupJob;

  /// Used by mount jobs for mounting.
  MountJob? mountJob;

  /// Used by Behavior.buyShip for buying a ship.
  ShipBuyJob? shipBuyJob;

  /// Used by Behavior.miner for mining.
  ExtractionJob? extractionJob;

  /// Used by Behavior.systemWatcher for watching a system.
  SystemWatcherJob? systemWatcherJob;

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
      'buyJob': buyJob?.toJson(),
      'deliverJob': deliverJob?.toJson(),
      'shipBuyJob': shipBuyJob?.toJson(),
      'mountJob': mountJob?.toJson(),
      'pickupJob': pickupJob?.toJson(),
      'extractionJob': extractionJob?.toJson(),
      'systemWatcherJob': systemWatcherJob?.toJson(),
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

  /// Create a new buy job from JSON, or null if the JSON is null.
  static BuyJob? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : BuyJob.fromJson(json);

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
@immutable
class DeliverJob {
  /// Create a new deliver job.
  const DeliverJob({
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

  /// Create a new deliver job from JSON, or null if the JSON is null.
  static DeliverJob? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : DeliverJob.fromJson(json);

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

/// Pickup tradeSymbol from deliveryShip at waypointSymbol.
@immutable
class PickupJob {
  /// Create a new pickup job.
  const PickupJob({
    required this.tradeSymbol,
    required this.waypointSymbol,
  });

  /// Create a new pickup job from JSON.
  factory PickupJob.fromJson(Map<String, dynamic> json) {
    final tradeSymbol = TradeSymbol.fromJson(json['tradeSymbol'] as String)!;
    final waypointSymbol =
        WaypointSymbol.fromJson(json['waypointSymbol'] as String);
    return PickupJob(
      tradeSymbol: tradeSymbol,
      waypointSymbol: waypointSymbol,
    );
  }

  /// Create a new pickup job from JSON, or null if the JSON is null.
  static PickupJob? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : PickupJob.fromJson(json);

  /// The item to pickup from delivery ship.
  // This should support multiple items.
  final TradeSymbol tradeSymbol;

  /// Where we plan to pickup from.
  // Should this have the ship symbol too?
  final WaypointSymbol waypointSymbol;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tradeSymbol': tradeSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
    };
  }
}

/// Mount the given mountSymbol at the given shipyardSymbol.
@immutable
class MountJob {
  /// Create a new mount job.
  const MountJob({
    required this.mountSymbol,
    required this.shipyardSymbol,
  });

  /// Create a new mount job from JSON.
  factory MountJob.fromJson(Map<String, dynamic> json) {
    final mountSymbol =
        ShipMountSymbolEnum.fromJson(json['mountSymbol'] as String)!;
    final shipyardSymbol =
        WaypointSymbol.fromJson(json['shipyardSymbol'] as String);
    return MountJob(
      mountSymbol: mountSymbol,
      shipyardSymbol: shipyardSymbol,
    );
  }

  /// Create a new mount job from JSON, or null if the JSON is null.
  static MountJob? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : MountJob.fromJson(json);

  /// The item we plan to mount (needs to be in inventory).
  // Should this support multiple mounts?
  final ShipMountSymbolEnum mountSymbol;

  /// What shipyard we plan to use for doing the mounting.
  final WaypointSymbol shipyardSymbol;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mountSymbol': mountSymbol.toJson(),
      'shipyardSymbol': shipyardSymbol.toJson(),
    };
  }
}

/// Job to buy a ship.
@immutable
class ShipBuyJob {
  /// Create a new ship buy job.
  const ShipBuyJob({
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

  /// Create a new ship buy job from JSON, or null if the JSON is null.
  static ShipBuyJob? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : ShipBuyJob.fromJson(json);

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

Map<String, dynamic> _marketForGoodToJson(
  Map<TradeSymbol, WaypointSymbol> marketForGood,
) {
  return Map.fromEntries(
    marketForGood.entries.map(
      (e) => MapEntry(
        e.key.toJson(),
        e.value.toJson(),
      ),
    ),
  );
}

Map<TradeSymbol, WaypointSymbol> _marketForGoodFromJson(
  Map<String, dynamic> json,
) {
  return Map.fromEntries(
    json.entries.map(
      (e) => MapEntry(
        TradeSymbol.fromJson(e.key)!,
        WaypointSymbol.fromJson(e.value as String),
      ),
    ),
  );
}

/// Type of extraction.
enum ExtractionType {
  /// Mining with a laser.
  mine,

  /// Siphoning with a siphon.
  siphon;

  /// Create from JSON.
  factory ExtractionType.fromJson(String json) =>
      values.firstWhere((b) => b.name == json);

  /// Convert this to JSON.
  String toJson() => name;
}

/// Extract resources.
@immutable
class ExtractionJob {
  /// Create a new extraction job.
  const ExtractionJob({
    required this.source,
    required this.marketForGood,
    required this.extractionType,
  });

  /// Create a new ExtractionJob from JSON.
  factory ExtractionJob.fromJson(Map<String, dynamic> json) {
    final source = WaypointSymbol.fromJson(json['source'] as String);
    final extractionType =
        ExtractionType.fromJson(json['extractionType'] as String);
    final marketForGood =
        _marketForGoodFromJson(json['marketForGood'] as Map<String, dynamic>);
    return ExtractionJob(
      source: source,
      marketForGood: marketForGood,
      extractionType: extractionType,
    );
  }

  /// Create a new mine job from JSON, or null if the JSON is null.
  static ExtractionJob? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : ExtractionJob.fromJson(json);

  /// The mine to extract from.
  final WaypointSymbol source;

  /// Where we expect to sell each good produced by the mine.
  final Map<TradeSymbol, WaypointSymbol> marketForGood;

  /// The type of extraction.
  final ExtractionType extractionType;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source': source.toJson(),
      'extractionType': extractionType.toJson(),
      'marketForGood': _marketForGoodToJson(marketForGood),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractionJob &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          extractionType == other.extractionType &&
          const MapEquality<TradeSymbol, WaypointSymbol>()
              .equals(marketForGood, other.marketForGood);

  @override
  int get hashCode => Object.hashAll([
        source,
        extractionType,
        const MapEquality<TradeSymbol, WaypointSymbol>().hash(marketForGood),
      ]);
}

/// Watch a system's markets.
@immutable
class SystemWatcherJob {
  /// Create a new SystemWatcherJob.
  const SystemWatcherJob({
    required this.systemSymbol,
  });

  /// Create a new SystemWatcherJob from JSON.
  factory SystemWatcherJob.fromJson(Map<String, dynamic> json) {
    final systemSymbol = SystemSymbol.fromJson(json['systemSymbol'] as String);
    return SystemWatcherJob(
      systemSymbol: systemSymbol,
    );
  }

  /// Create a new SystemWatcherJob from JSON, or null if the JSON is null.
  static SystemWatcherJob? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : SystemWatcherJob.fromJson(json);

  /// The system to watch.
  final SystemSymbol systemSymbol;

  /// Convert this to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'systemSymbol': systemSymbol.toJson(),
    };
  }
}
