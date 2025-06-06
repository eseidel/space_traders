import 'package:openapi/model/ship_cargo_item.dart';
import 'package:openapi/model_helpers.dart';

class ShipCargo {
  ShipCargo({
    required this.capacity,
    required this.units,
    this.inventory = const [],
  });

  factory ShipCargo.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipCargo(
      capacity: json['capacity'] as int,
      units: json['units'] as int,
      inventory: (json['inventory'] as List)
          .map<ShipCargoItem>(
            (e) => ShipCargoItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipCargo? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipCargo.fromJson(json);
  }

  int capacity;
  int units;
  List<ShipCargoItem> inventory;

  Map<String, dynamic> toJson() {
    return {
      'capacity': capacity,
      'units': units,
      'inventory': inventory.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hash(capacity, units, inventory);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipCargo &&
        capacity == other.capacity &&
        units == other.units &&
        listsEqual(inventory, other.inventory);
  }
}
