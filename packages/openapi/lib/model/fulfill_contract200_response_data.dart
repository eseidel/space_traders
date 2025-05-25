import 'package:openapi/model/agent.dart';
import 'package:openapi/model/contract.dart';

class FulfillContract200ResponseData {
  FulfillContract200ResponseData({required this.contract, required this.agent});

  factory FulfillContract200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return FulfillContract200ResponseData(
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      agent: Agent.fromJson(json['agent'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static FulfillContract200ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return FulfillContract200ResponseData.fromJson(json);
  }

  Contract contract;
  Agent agent;

  Map<String, dynamic> toJson() {
    return {'contract': contract.toJson(), 'agent': agent.toJson()};
  }
}
