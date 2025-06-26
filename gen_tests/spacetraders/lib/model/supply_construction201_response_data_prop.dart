import 'package:meta/meta.dart';
import 'package:spacetraders/model/construction.dart';
import 'package:spacetraders/model/ship_cargo.dart';

@immutable
class SupplyConstruction201ResponseDataProp {
  const SupplyConstruction201ResponseDataProp({
    required this.construction,
    required this.cargo,
  });

  factory SupplyConstruction201ResponseDataProp.fromJson(
    Map<String, dynamic> json,
  ) {
    return SupplyConstruction201ResponseDataProp(
      construction: Construction.fromJson(
        json['construction'] as Map<String, dynamic>,
      ),
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SupplyConstruction201ResponseDataProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return SupplyConstruction201ResponseDataProp.fromJson(json);
  }

  final Construction construction;
  final ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'construction': construction.toJson(), 'cargo': cargo.toJson()};
  }

  @override
  int get hashCode => Object.hashAll([construction, cargo]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplyConstruction201ResponseDataProp &&
        construction == other.construction &&
        cargo == other.cargo;
  }
}
