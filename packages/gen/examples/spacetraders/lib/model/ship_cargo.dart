import 'package:spacetraders/model/ship_cargo_item.dart';

class ShipCargo {
  ShipCargo({
    required this.capacity,
    required this.units,
    required this.inventory,
  });

  factory ShipCargo.fromJson(Map<String, dynamic> json) {
    return ShipCargo(
      capacity: json['capacity'] as int,
      units: json['units'] as int,
      inventory:
          (json['inventory'] as List<dynamic>)
              .map<ShipCargoItem>(
                (e) => ShipCargoItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  final int capacity;
  final int units;
  final List<ShipCargoItem> inventory;

  Map<String, dynamic> toJson() {
    return {
      'capacity': capacity,
      'units': units,
      'inventory': inventory.map((e) => e.toJson()).toList(),
    };
  }
}
