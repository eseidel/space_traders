import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'get_transactions_response.g.dart';

@JsonSerializable()
class GetTransactionsResponse {
  GetTransactionsResponse({required this.transactions});

  factory GetTransactionsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetTransactionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetTransactionsResponseToJson(this);

  final List<Transaction> transactions;
}
