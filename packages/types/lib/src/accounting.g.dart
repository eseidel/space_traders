// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'accounting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BalanceSheet _$BalanceSheetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BalanceSheet', json, ($checkedConvert) {
      final val = BalanceSheet(
        time: $checkedConvert('time', (v) => DateTime.parse(v as String)),
        cash: $checkedConvert('cash', (v) => (v as num).toInt()),
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
    };

IncomeStatement _$IncomeStatementFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'IncomeStatement',
      json,
      ($checkedConvert) {
        final val = IncomeStatement(
          start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
          end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
          sales: $checkedConvert('sales', (v) => (v as num).toInt()),
          contracts: $checkedConvert('contracts', (v) => (v as num).toInt()),
          goods: $checkedConvert('goods', (v) => (v as num).toInt()),
          fuel: $checkedConvert('fuel', (v) => (v as num).toInt()),
          capEx: $checkedConvert('cap_ex', (v) => (v as num).toInt()),
          numberOfTransactions: $checkedConvert(
            'number_of_transactions',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'capEx': 'cap_ex',
        'numberOfTransactions': 'number_of_transactions',
      },
    );

Map<String, dynamic> _$IncomeStatementToJson(IncomeStatement instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'number_of_transactions': instance.numberOfTransactions,
      'sales': instance.sales,
      'contracts': instance.contracts,
      'goods': instance.goods,
      'fuel': instance.fuel,
      'cap_ex': instance.capEx,
    };
