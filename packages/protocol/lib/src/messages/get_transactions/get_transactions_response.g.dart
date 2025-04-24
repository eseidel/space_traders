// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter, require_trailing_commas, cast_nullable_to_non_nullable, lines_longer_than_80_chars

part of 'get_transactions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetTransactionsResponse _$GetTransactionsResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GetTransactionsResponse', json, ($checkedConvert) {
  final val = GetTransactionsResponse(
    transactions: $checkedConvert(
      'transactions',
      (v) =>
          (v as List<dynamic>)
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList(),
    ),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$GetTransactionsResponseToJson(
  GetTransactionsResponse instance,
) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'transactions': instance.transactions.map((e) => e.toJson()).toList(),
};
