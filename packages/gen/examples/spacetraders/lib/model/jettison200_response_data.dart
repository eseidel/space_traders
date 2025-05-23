import 'package:spacetraders/model/ship_cargo.dart';

class Jettison200ResponseData {
  Jettison200ResponseData({required this.cargo});

  factory Jettison200ResponseData.fromJson(Map<String, dynamic> json) {
    return Jettison200ResponseData(
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  final ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'cargo': cargo.toJson()};
  }
}
