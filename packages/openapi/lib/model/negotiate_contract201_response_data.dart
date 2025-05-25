import 'package:openapi/model/contract.dart';

class NegotiateContract201ResponseData {
  NegotiateContract201ResponseData({required this.contract});

  factory NegotiateContract201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return NegotiateContract201ResponseData(
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static NegotiateContract201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return NegotiateContract201ResponseData.fromJson(json);
  }

  Contract contract;

  Map<String, dynamic> toJson() {
    return {'contract': contract.toJson()};
  }
}
