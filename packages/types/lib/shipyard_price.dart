import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Price data for a single ship type in a shipyard.
@immutable
class ShipyardPrice {
  /// Create a new price record.
  const ShipyardPrice({
    required this.waypointSymbol,
    required this.shipType,
    required this.purchasePrice,
    required this.timestamp,
  });

  /// Create a new price record from a ShipyardShip.
  factory ShipyardPrice.fromShipyardShip(
    ShipyardShip ship,
    WaypointSymbol waypoint,
  ) {
    return ShipyardPrice(
      waypointSymbol: waypoint,
      shipType: ship.type!,
      purchasePrice: ship.purchasePrice,
      timestamp: DateTime.timestamp(),
    );
  }

  /// Create a new price record from JSON.
  factory ShipyardPrice.fromJson(Map<String, dynamic> json) {
    return ShipyardPrice(
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      shipType: ShipType.fromJson(json['shipType'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// The waypoint of the market where this price was recorded.
  final WaypointSymbol waypointSymbol;

  /// The symbol of the ship type.
  final ShipType shipType;

  /// The price at which this good can be purchased from the market.
  final int purchasePrice;

  /// The timestamp of the price record.
  final DateTime timestamp;

  /// Convert this price record to JSON.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['waypointSymbol'] = waypointSymbol.toJson();
    json['shipType'] = shipType.toJson();
    json['purchasePrice'] = purchasePrice;
    json['timestamp'] = timestamp.toUtc().toIso8601String();
    return json;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipyardPrice &&
          runtimeType == other.runtimeType &&
          waypointSymbol == other.waypointSymbol &&
          shipType == other.shipType &&
          purchasePrice == other.purchasePrice &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        waypointSymbol,
        shipType,
        purchasePrice,
        timestamp,
      );
}
