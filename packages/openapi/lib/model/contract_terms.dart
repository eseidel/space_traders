import 'package:openapi/model/contract_deliver_good.dart';
import 'package:openapi/model/contract_payment.dart';
import 'package:openapi/model_helpers.dart';

class ContractTerms {
  ContractTerms({
    required this.deadline,
    required this.payment,
    this.deliver = const [],
  });

  factory ContractTerms.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ContractTerms(
      deadline: DateTime.parse(json['deadline'] as String),
      payment: ContractPayment.fromJson(
        json['payment'] as Map<String, dynamic>,
      ),
      deliver:
          (json['deliver'] as List<dynamic>)
              .map<ContractDeliverGood>(
                (e) => ContractDeliverGood.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ContractTerms? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ContractTerms.fromJson(json);
  }

  DateTime deadline;
  ContractPayment payment;
  List<ContractDeliverGood> deliver;

  Map<String, dynamic> toJson() {
    return {
      'deadline': deadline.toIso8601String(),
      'payment': payment.toJson(),
      'deliver': deliver.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hash(deadline, payment, deliver);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContractTerms &&
        deadline == other.deadline &&
        payment == other.payment &&
        listsEqual(deliver, other.deliver);
  }
}
