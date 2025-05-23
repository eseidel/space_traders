import 'package:spacetraders/model/construction.dart';
import 'package:spacetraders/model/ship_cargo.dart';

class SupplyConstruction201ResponseData {
  SupplyConstruction201ResponseData({
    required this.construction,
    required this.cargo,
  });

  factory SupplyConstruction201ResponseData.fromJson(
    Map<String, dynamic> json,
  ) {
    return SupplyConstruction201ResponseData(
      construction: Construction.fromJson(
        json['construction'] as Map<String, dynamic>,
      ),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  final Construction construction;
  final ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'construction': construction.toJson(), 'cargo': cargo.toJson()};
  }
}
