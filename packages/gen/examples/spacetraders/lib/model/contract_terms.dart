import 'package:spacetraders/model/contract_deliver_good.dart';
import 'package:spacetraders/model/contract_payment.dart';

class ContractTerms {
  ContractTerms({
    required this.deadline,
    required this.payment,
    required this.deliver,
  });

  factory ContractTerms.fromJson(Map<String, dynamic> json) {
    return ContractTerms(
      deadline: DateTime.parse(json['deadline'] as String),
      payment:
          ContractPayment.fromJson(json['payment'] as Map<String, dynamic>),
      deliver: (json['deliver'] as List<dynamic>)
          .map<ContractDeliverGood>(
            (e) => ContractDeliverGood.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final DateTime deadline;
  final ContractPayment payment;
  final List<ContractDeliverGood> deliver;

  Map<String, dynamic> toJson() {
    return {
      'deadline': deadline.toIso8601String(),
      'payment': payment.toJson(),
      'deliver': deliver.map((e) => e.toJson()).toList(),
    };
  }
}
