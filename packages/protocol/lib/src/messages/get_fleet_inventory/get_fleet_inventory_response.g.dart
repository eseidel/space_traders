// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_fleet_inventory_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemValue _$ItemValueFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ItemValue',
  json,
  ($checkedConvert) {
    final val = ItemValue(
      tradeSymbol: $checkedConvert(
        'trade_symbol',
        (v) => const TradeSymbolConverter().fromJson(v as String),
      ),
      count: $checkedConvert('count', (v) => (v as num).toInt()),
      medianPrice: $checkedConvert('median_price', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'tradeSymbol': 'trade_symbol',
    'medianPrice': 'median_price',
  },
);

Map<String, dynamic> _$ItemValueToJson(ItemValue instance) => <String, dynamic>{
  'trade_symbol': const TradeSymbolConverter().toJson(instance.tradeSymbol),
  'count': instance.count,
  'median_price': instance.medianPrice,
};

GetFleetInventoryResponse _$GetFleetInventoryResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GetFleetInventoryResponse', json, ($checkedConvert) {
  final val = GetFleetInventoryResponse(
    items: $checkedConvert(
      'items',
      (v) =>
          (v as List<dynamic>)
              .map((e) => ItemValue.fromJson(e as Map<String, dynamic>))
              .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$GetFleetInventoryResponseToJson(
  GetFleetInventoryResponse instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
