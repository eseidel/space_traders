// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_fleet_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PricedItem _$PricedItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PricedItem',
  json,
  ($checkedConvert) {
    final val = PricedItem(
      symbol: $checkedConvert('symbol', (v) => v as String),
      pricePerUnit: $checkedConvert(
        'price_per_unit',
        (v) => (v as num).toInt(),
      ),
      units: $checkedConvert('units', (v) => (v as num).toInt()),
      totalPrice: $checkedConvert('total_price', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'pricePerUnit': 'price_per_unit',
    'totalPrice': 'total_price',
  },
);

Map<String, dynamic> _$PricedItemToJson(PricedItem instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'price_per_unit': instance.pricePerUnit,
      'units': instance.units,
      'total_price': instance.totalPrice,
    };

Cargo _$CargoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Cargo', json, ($checkedConvert) {
      final val = Cargo(
        capacity: $checkedConvert('capacity', (v) => (v as num).toInt()),
        units: $checkedConvert('units', (v) => (v as num).toInt()),
        inventory: $checkedConvert(
          'inventory',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => PricedItem.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CargoToJson(Cargo instance) => <String, dynamic>{
  'capacity': instance.capacity,
  'units': instance.units,
  'inventory': instance.inventory.map((e) => e.toJson()).toList(),
};

RoutePlan _$RoutePlanFromJson(Map<String, dynamic> json) => $checkedCreate(
  'RoutePlan',
  json,
  ($checkedConvert) {
    final val = RoutePlan(
      waypointSymbol: $checkedConvert('waypoint_symbol', (v) => v as String),
      timeToArrival: $checkedConvert(
        'time_to_arrival',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'waypointSymbol': 'waypoint_symbol',
    'timeToArrival': 'time_to_arrival',
  },
);

Map<String, dynamic> _$RoutePlanToJson(RoutePlan instance) => <String, dynamic>{
  'waypoint_symbol': instance.waypointSymbol,
  'time_to_arrival': instance.timeToArrival,
};

FleetShip _$FleetShipFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FleetShip', json, ($checkedConvert) {
      final val = FleetShip(
        symbol: $checkedConvert('symbol', (v) => v as String),
        route: $checkedConvert(
          'route',
          (v) => RoutePlan.fromJson(v as Map<String, dynamic>),
        ),
        cargo: $checkedConvert(
          'cargo',
          (v) => Cargo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FleetShipToJson(FleetShip instance) => <String, dynamic>{
  'symbol': instance.symbol,
  'route': instance.route.toJson(),
  'cargo': instance.cargo.toJson(),
};

GetFleetResponse _$GetFleetResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GetFleetResponse', json, ($checkedConvert) {
      final val = GetFleetResponse(
        ships: $checkedConvert(
          'ships',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => FleetShip.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GetFleetResponseToJson(GetFleetResponse instance) =>
    <String, dynamic>{'ships': instance.ships.map((e) => e.toJson()).toList()};
