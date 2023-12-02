import 'package:meta/meta.dart';
import 'package:types/price.dart';
import 'package:types/types.dart';

/// Price data for a single ship type in a shipyard.
@immutable
class ShipyardPrice extends PriceBase<ShipType> {
  /// Create a new price record.
  const ShipyardPrice({
    required super.waypointSymbol,
    required ShipType shipType,
    required this.purchasePrice,
    required super.timestamp,
  }) : super(symbol: shipType);

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

  /// The price at which this good can be purchased from the market.
  final int purchasePrice;

  @override
  List<Object> get props =>
      [waypointSymbol, shipType, purchasePrice, timestamp];

  /// The symbol of the ship type.
  ShipType get shipType => symbol;

  /// Convert this price record to JSON.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['waypointSymbol'] = waypointSymbol.toJson();
    json['shipType'] = shipType.toJson();
    json['purchasePrice'] = purchasePrice;
    json['timestamp'] = timestamp.toUtc().toIso8601String();
    return json;
  }
}
