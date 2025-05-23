import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_fleet_response.g.dart';

@JsonSerializable()
class PricedItem extends Equatable {
  const PricedItem({
    required this.symbol,
    required this.pricePerUnit,
    required this.units,
    required this.totalPrice,
  });

  factory PricedItem.fromJson(Map<String, dynamic> json) =>
      _$PricedItemFromJson(json);

  final String symbol;
  final int pricePerUnit;
  final int units;
  final int totalPrice;

  Map<String, dynamic> toJson() => _$PricedItemToJson(this);

  @override
  List<Object?> get props => [symbol, pricePerUnit, units, totalPrice];
}

@JsonSerializable()
class Cargo extends Equatable {
  const Cargo({
    required this.capacity,
    required this.units,
    required this.inventory,
  });

  factory Cargo.fromJson(Map<String, dynamic> json) => _$CargoFromJson(json);

  final int capacity;
  final int units;
  final List<PricedItem> inventory;

  Map<String, dynamic> toJson() => _$CargoToJson(this);

  @override
  List<Object?> get props => [capacity, units, inventory];
}

@JsonSerializable()
class ShipRoutePlan extends Equatable {
  const ShipRoutePlan({
    required this.waypointSymbol,
    required this.timeToArrival,
  });

  factory ShipRoutePlan.fromJson(Map<String, dynamic> json) =>
      _$ShipRoutePlanFromJson(json);

  final String waypointSymbol;
  final int timeToArrival;

  Map<String, dynamic> toJson() => _$ShipRoutePlanToJson(this);

  @override
  List<Object?> get props => [waypointSymbol, timeToArrival];
}

@JsonSerializable()
class FleetShip extends Equatable {
  const FleetShip({
    required this.symbol,
    required this.route,
    required this.cargo,
  });

  factory FleetShip.fromJson(Map<String, dynamic> json) =>
      _$FleetShipFromJson(json);

  final String symbol;
  final ShipRoutePlan route;
  final Cargo cargo;

  Map<String, dynamic> toJson() => _$FleetShipToJson(this);

  @override
  List<Object?> get props => [symbol, route, cargo];
}

@JsonSerializable()
class GetFleetResponse extends Equatable {
  const GetFleetResponse({required this.ships});

  factory GetFleetResponse.fromJson(Map<String, dynamic> json) =>
      _$GetFleetResponseFromJson(json);

  final List<FleetShip> ships;

  Map<String, dynamic> toJson() => _$GetFleetResponseToJson(this);

  @override
  List<Object?> get props => [ships];
}
