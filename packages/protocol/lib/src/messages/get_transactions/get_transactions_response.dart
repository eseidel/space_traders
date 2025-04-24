import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'get_transactions_response.g.dart';

@JsonSerializable()
class GetTransactionsResponse {
  GetTransactionsResponse({
    required this.transactions,
    required this.timestamp,
  });

  factory GetTransactionsResponse.fromJson(Map<String, dynamic> json) =>
      _$GetTransactionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetTransactionsResponseToJson(this);

  /// So that the client can determine server-time to which the transactions
  /// are all relative.
  final DateTime timestamp;

  final List<Transaction> transactions;
}
