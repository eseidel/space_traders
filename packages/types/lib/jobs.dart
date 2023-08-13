import 'package:meta/meta.dart';
import 'package:types/types.dart';

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
