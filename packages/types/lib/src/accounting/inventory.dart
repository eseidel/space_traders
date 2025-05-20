import 'package:json_annotation/json_annotation.dart';
import 'package:types/api_converters.dart';
import 'package:types/types.dart';

part 'inventory.g.dart';

/// A class representing the value of an item in the inventory.
@JsonSerializable()
class PricedItemStack {
  /// Creates an instance of [PricedItemStack].
  PricedItemStack({
    required this.tradeSymbol,
    required this.count,
    required this.pricePerUnit,
  });

  /// Creates an instance of [PricedItemStack] from a JSON object.
  factory PricedItemStack.fromJson(Map<String, dynamic> json) =>
      _$PricedItemStackFromJson(json);

  /// The trade symbol of the item.
  @TradeSymbolConverter()
  final TradeSymbol tradeSymbol;

  /// Number of items of this type in the inventory.
  final int count;

  /// The price of the item if available.
  final int? pricePerUnit;

  /// The total value of the item.
  int? get totalValue {
    if (pricePerUnit == null) {
      return null;
    }
    return count * pricePerUnit!;
  }

  /// Converts the [PricedItemStack] to a JSON object.
  Map<String, dynamic> toJson() => _$PricedItemStackToJson(this);
}

/// A class representing the value of the inventory.
@JsonSerializable()
class PricedInventory {
  /// Creates an instance of [PricedInventory].
  PricedInventory({required this.items});

  /// Creates an instance of [PricedInventory] from a JSON object.
  factory PricedInventory.fromJson(Map<String, dynamic> json) =>
      _$PricedInventoryFromJson(json);

  /// Converts the [PricedInventory] to a JSON object.
  Map<String, dynamic> toJson() => _$PricedInventoryToJson(this);

  /// Set of items in the inventory missing prices.
  Set<TradeSymbol> get missingPrices {
    return items
        .where((item) => item.pricePerUnit == null)
        .map((item) => item.tradeSymbol)
        .toSet();
  }

  /// The total value of the inventory.
  int get totalValue {
    return items.fold(0, (total, item) {
      return total + (item.count * (item.pricePerUnit ?? 0));
    });
  }

  /// List of items in the inventory.
  final List<PricedItemStack> items;
}

/// A class representing the value of an ship in the fleet.
@JsonSerializable()
class PricedShip {
  /// Creates an instance of [PricedShip].
  PricedShip({
    required this.shipType,
    required this.count,
    required this.pricePerUnit,
  });

  /// Creates an instance of [PricedShip] from a JSON object.
  factory PricedShip.fromJson(Map<String, dynamic> json) =>
      _$PricedShipFromJson(json);

  /// Type of the ship.
  /// Can be null if the ship type is unknown.
  @ShipTypeConverter()
  final ShipType? shipType;

  /// Number of ships of this type.
  final int count;

  /// The median price of the ship type if available.
  final int? pricePerUnit;

  /// The total value of these ships.
  int get totalValue => count * (pricePerUnit ?? 0);

  /// Converts the [PricedShip] to a JSON object.
  Map<String, dynamic> toJson() => _$PricedShipToJson(this);
}

/// A class representing the value of the inventory.
@JsonSerializable()
class PricedFleet {
  /// Creates an instance of [PricedFleet].
  PricedFleet({required this.ships});

  /// Creates an instance of [PricedFleet] from a JSON object.
  factory PricedFleet.fromJson(Map<String, dynamic> json) =>
      _$PricedFleetFromJson(json);

  /// Converts the [PricedFleet] to a JSON object.
  Map<String, dynamic> toJson() => _$PricedFleetToJson(this);

  /// Set of ship types in the fleet missing prices.
  Set<ShipType?> get missingPrices {
    return ships
        .where((s) => s.pricePerUnit == null)
        .map((s) => s.shipType)
        .toSet();
  }

  /// The total value of the fleet.
  /// Does not currently include mounts.
  int get totalValue {
    return ships.fold(0, (total, s) {
      return total + (s.count * (s.pricePerUnit ?? 0));
    });
  }

  /// List of ships in the fleet.
  final List<PricedShip> ships;
}
