// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_deals_nearby_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DealsNearbyResponse _$DealsNearbyResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DealsNearbyResponse',
      json,
      ($checkedConvert) {
        final val = DealsNearbyResponse(
          deals: $checkedConvert(
            'deals',
            (v) => (v as List<dynamic>)
                .map((e) => NearbyDeal.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          shipType: $checkedConvert(
            'ship_type',
            (v) => const ShipTypeConverter().fromJson(v as String),
          ),
          shipSpec: $checkedConvert(
            'ship_spec',
            (v) => ShipSpec.fromJson(v as Map<String, dynamic>),
          ),
          startSymbol: $checkedConvert(
            'start_symbol',
            (v) => WaypointSymbol.fromJson(v as String),
          ),
          credits: $checkedConvert('credits', (v) => (v as num).toInt()),
          extraSellOpps: $checkedConvert(
            'extra_sell_opps',
            (v) => (v as List<dynamic>)
                .map((e) => SellOpp.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          tradeSymbolCount: $checkedConvert(
            'trade_symbol_count',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'shipType': 'ship_type',
        'shipSpec': 'ship_spec',
        'startSymbol': 'start_symbol',
        'extraSellOpps': 'extra_sell_opps',
        'tradeSymbolCount': 'trade_symbol_count',
      },
    );

Map<String, dynamic> _$DealsNearbyResponseToJson(
  DealsNearbyResponse instance,
) => <String, dynamic>{
  'deals': instance.deals.map((e) => e.toJson()).toList(),
  'ship_type': const ShipTypeConverter().toJson(instance.shipType),
  'ship_spec': instance.shipSpec.toJson(),
  'start_symbol': instance.startSymbol.toJson(),
  'credits': instance.credits,
  'extra_sell_opps': instance.extraSellOpps.map((e) => e.toJson()).toList(),
  'trade_symbol_count': instance.tradeSymbolCount,
};

NearbyDeal _$NearbyDealFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NearbyDeal', json, ($checkedConvert) {
      final val = NearbyDeal(
        costed: $checkedConvert(
          'costed',
          (v) => CostedDeal.fromJson(v as Map<String, dynamic>),
        ),
        inProgress: $checkedConvert('in_progress', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'inProgress': 'in_progress'});

Map<String, dynamic> _$NearbyDealToJson(NearbyDeal instance) =>
    <String, dynamic>{
      'costed': instance.costed.toJson(),
      'in_progress': instance.inProgress,
    };
