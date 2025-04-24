// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'reports.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BalanceSheet _$BalanceSheetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BalanceSheet', json, ($checkedConvert) {
      final val = BalanceSheet(
        time: $checkedConvert('time', (v) => DateTime.parse(v as String)),
        cash: $checkedConvert('cash', (v) => (v as num).toInt()),
        loans: $checkedConvert('loans', (v) => (v as num).toInt()),
        inventory: $checkedConvert('inventory', (v) => (v as num).toInt()),
        ships: $checkedConvert('ships', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$BalanceSheetToJson(BalanceSheet instance) =>
    <String, dynamic>{
      'time': instance.time.toIso8601String(),
      'cash': instance.cash,
      'inventory': instance.inventory,
      'ships': instance.ships,
      'loans': instance.loans,
    };

IncomeStatement _$IncomeStatementFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'IncomeStatement',
  json,
  ($checkedConvert) {
    final val = IncomeStatement(
      start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
      end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
      goodsRevenue: $checkedConvert('goods_revenue', (v) => (v as num).toInt()),
      contractsRevenue: $checkedConvert(
        'contracts_revenue',
        (v) => (v as num).toInt(),
      ),
      goodsPurchase: $checkedConvert(
        'goods_purchase',
        (v) => (v as num).toInt(),
      ),
      assetSale: $checkedConvert('asset_sale', (v) => (v as num).toInt()),
      constructionMaterials: $checkedConvert(
        'construction_materials',
        (v) => (v as num).toInt(),
      ),
      fuelPurchase: $checkedConvert('fuel_purchase', (v) => (v as num).toInt()),
      capEx: $checkedConvert('cap_ex', (v) => (v as num).toInt()),
      numberOfTransactions: $checkedConvert(
        'number_of_transactions',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'goodsRevenue': 'goods_revenue',
    'contractsRevenue': 'contracts_revenue',
    'goodsPurchase': 'goods_purchase',
    'assetSale': 'asset_sale',
    'constructionMaterials': 'construction_materials',
    'fuelPurchase': 'fuel_purchase',
    'capEx': 'cap_ex',
    'numberOfTransactions': 'number_of_transactions',
  },
);

Map<String, dynamic> _$IncomeStatementToJson(IncomeStatement instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'number_of_transactions': instance.numberOfTransactions,
      'goods_revenue': instance.goodsRevenue,
      'contracts_revenue': instance.contractsRevenue,
      'asset_sale': instance.assetSale,
      'goods_purchase': instance.goodsPurchase,
      'fuel_purchase': instance.fuelPurchase,
      'construction_materials': instance.constructionMaterials,
      'cap_ex': instance.capEx,
    };
