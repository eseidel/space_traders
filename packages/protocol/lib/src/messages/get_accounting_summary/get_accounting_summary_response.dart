import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'get_accounting_summary_response.g.dart';

@JsonSerializable()
class AccountingSummaryResponse extends Equatable {
  const AccountingSummaryResponse({
    required this.balanceSheet,
    required this.incomeStatement,
  });

  factory AccountingSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$AccountingSummaryResponseFromJson(json);

  final BalanceSheet balanceSheet;
  final IncomeStatement incomeStatement;

  Map<String, dynamic> toJson() => _$AccountingSummaryResponseToJson(this);

  @override
  List<Object?> get props => [balanceSheet, incomeStatement];
}
