// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_accounting_summary_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountingSummaryResponse _$AccountingSummaryResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AccountingSummaryResponse',
  json,
  ($checkedConvert) {
    final val = AccountingSummaryResponse(
      balanceSheet: $checkedConvert(
        'balance_sheet',
        (v) => BalanceSheet.fromJson(v as Map<String, dynamic>),
      ),
      incomeStatement: $checkedConvert(
        'income_statement',
        (v) => IncomeStatement.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'balanceSheet': 'balance_sheet',
    'incomeStatement': 'income_statement',
  },
);

Map<String, dynamic> _$AccountingSummaryResponseToJson(
  AccountingSummaryResponse instance,
) => <String, dynamic>{
  'balance_sheet': instance.balanceSheet.toJson(),
  'income_statement': instance.incomeStatement.toJson(),
};
