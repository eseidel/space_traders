import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Object which caches all the static data for a shipyard.
@immutable
class ShipyardListing {
  /// Creates a new shipyard listing.
  const ShipyardListing({
    required this.waypointSymbol,
    required this.shipTypes,
  });

  /// Creates a shipyard listing with a fallback value.
  @visibleForTesting
  ShipyardListing.fallbackValue()
    : waypointSymbol = WaypointSymbol.fromString('W-A-Y'),
      shipTypes = {};

  /// Creates a new shipyard description from JSON data.
  factory ShipyardListing.fromJson(Map<String, dynamic> json) {
    final symbol = WaypointSymbol.fromJson(json['waypointSymbol'] as String);
    final shipTypes = (json['shipTypes'] as List<dynamic>)
        .map((e) => ShipType.fromJson(e as String))
        .toSet();

    return ShipyardListing(waypointSymbol: symbol, shipTypes: shipTypes);
  }

  /// The symbol of the shipyard. The symbol is the same as the waypoint where
  /// the shipyard is located.
  final WaypointSymbol waypointSymbol;

  /// Ships which are sold at the shipyard.
  final Set<ShipType> shipTypes;

  /// Whether this shipyard sells the given ship type.
  bool hasShip(ShipType shipType) => shipTypes.contains(shipType);

  /// Converts this shipyard description to JSON data.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'waypointSymbol': waypointSymbol.toJson(),
      'shipTypes': shipTypes.map((t) => t.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    const equality = SetEquality<ShipType>();
    return identical(this, other) ||
        other is ShipyardListing &&
            runtimeType == other.runtimeType &&
            waypointSymbol == other.waypointSymbol &&
            equality.equals(shipTypes, other.shipTypes);
  }

  @override
  int get hashCode => Object.hashAll([waypointSymbol, ...shipTypes]);
}
