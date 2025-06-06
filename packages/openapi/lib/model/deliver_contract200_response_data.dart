import 'package:openapi/model/contract.dart';
import 'package:openapi/model/ship_cargo.dart';

class DeliverContract200ResponseData {
  DeliverContract200ResponseData({required this.contract, required this.cargo});

  factory DeliverContract200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return DeliverContract200ResponseData(
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static DeliverContract200ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return DeliverContract200ResponseData.fromJson(json);
  }

  Contract contract;
  ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'contract': contract.toJson(), 'cargo': cargo.toJson()};
  }

  @override
  int get hashCode => Object.hash(contract, cargo);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliverContract200ResponseData &&
        contract == other.contract &&
        cargo == other.cargo;
  }
}
