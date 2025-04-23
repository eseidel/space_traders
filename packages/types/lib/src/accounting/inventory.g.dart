// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PricedItemStack _$PricedItemStackFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PricedItemStack',
      json,
      ($checkedConvert) {
        final val = PricedItemStack(
          tradeSymbol: $checkedConvert(
            'trade_symbol',
            (v) => const TradeSymbolConverter().fromJson(v as String),
          ),
          count: $checkedConvert('count', (v) => (v as num).toInt()),
          pricePerUnit: $checkedConvert(
            'price_per_unit',
            (v) => (v as num?)?.toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'tradeSymbol': 'trade_symbol',
        'pricePerUnit': 'price_per_unit',
      },
    );

Map<String, dynamic> _$PricedItemStackToJson(PricedItemStack instance) =>
    <String, dynamic>{
      'trade_symbol': const TradeSymbolConverter().toJson(instance.tradeSymbol),
      'count': instance.count,
      'price_per_unit': instance.pricePerUnit,
    };

PricedInventory _$PricedInventoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PricedInventory', json, ($checkedConvert) {
      final val = PricedInventory(
        items: $checkedConvert(
          'items',
          (v) =>
              (v as List<dynamic>)
                  .map(
                    (e) => PricedItemStack.fromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PricedInventoryToJson(PricedInventory instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

PricedShip _$PricedShipFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PricedShip',
  json,
  ($checkedConvert) {
    final val = PricedShip(
      shipType: $checkedConvert(
        'ship_type',
        (v) => const ShipTypeConverter().fromJson(v as String),
      ),
      count: $checkedConvert('count', (v) => (v as num).toInt()),
      pricePerUnit: $checkedConvert(
        'price_per_unit',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'shipType': 'ship_type',
    'pricePerUnit': 'price_per_unit',
  },
);

Map<String, dynamic> _$PricedShipToJson(PricedShip instance) =>
    <String, dynamic>{
      'ship_type': const ShipTypeConverter().toJson(instance.shipType),
      'count': instance.count,
      'price_per_unit': instance.pricePerUnit,
    };

PricedFleet _$PricedFleetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PricedFleet', json, ($checkedConvert) {
      final val = PricedFleet(
        ships: $checkedConvert(
          'ships',
          (v) =>
              (v as List<dynamic>)
                  .map((e) => PricedShip.fromJson(e as Map<String, dynamic>))
                  .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PricedFleetToJson(PricedFleet instance) =>
    <String, dynamic>{'ships': instance.ships.map((e) => e.toJson()).toList()};
