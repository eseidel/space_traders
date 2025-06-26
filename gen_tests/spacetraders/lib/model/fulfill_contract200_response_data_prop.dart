import 'package:meta/meta.dart';
import 'package:spacetraders/model/agent.dart';
import 'package:spacetraders/model/contract.dart';

@immutable
class FulfillContract200ResponseDataProp {
  const FulfillContract200ResponseDataProp({
    required this.contract,
    required this.agent,
  });

  factory FulfillContract200ResponseDataProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return FulfillContract200ResponseDataProp(
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static FulfillContract200ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return FulfillContract200ResponseDataProp.fromJson(json);
  }

  final Contract contract;
  final Agent agent;

  Map<String, dynamic> toJson() {
    return {'contract': contract.toJson(), 'agent': agent.toJson()};
  }

  @override
  int get hashCode => Object.hashAll([contract, agent]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FulfillContract200ResponseDataProp &&
        contract == other.contract &&
        agent == other.agent;
  }
}
