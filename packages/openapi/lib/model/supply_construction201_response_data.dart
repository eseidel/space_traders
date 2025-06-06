import 'package:openapi/model/construction.dart';
import 'package:openapi/model/ship_cargo.dart';

class SupplyConstruction201ResponseData {
  SupplyConstruction201ResponseData({
    required this.construction,
    required this.cargo,
  });

  factory SupplyConstruction201ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SupplyConstruction201ResponseData(
      construction: Construction.fromJson(
        json['construction'] as Map<String, dynamic>,
      ),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SupplyConstruction201ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return SupplyConstruction201ResponseData.fromJson(json);
  }

  Construction construction;
  ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'construction': construction.toJson(), 'cargo': cargo.toJson()};
  }

  @override
  int get hashCode => Object.hash(construction, cargo);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplyConstruction201ResponseData &&
        construction == other.construction &&
        cargo == other.cargo;
  }
}
