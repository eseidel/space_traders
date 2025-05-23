import 'package:spacetraders/model/contract.dart';
import 'package:spacetraders/model/ship_cargo.dart';

class DeliverContract200ResponseData {
  DeliverContract200ResponseData({required this.contract, required this.cargo});

  factory DeliverContract200ResponseData.fromJson(Map<String, dynamic> json) {
    return DeliverContract200ResponseData(
      contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  final Contract contract;
  final ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'contract': contract.toJson(), 'cargo': cargo.toJson()};
  }
}
