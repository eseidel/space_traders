import 'package:openapi/model/ship_type.dart';

class ShipyardShipTypesInner {
  ShipyardShipTypesInner({required this.type});

  factory ShipyardShipTypesInner.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipyardShipTypesInner(
      type: ShipType.fromJson(json['type'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipyardShipTypesInner? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipyardShipTypesInner.fromJson(json);
  }

  ShipType type;

  Map<String, dynamic> toJson() {
    return {'type': type.toJson()};
  }

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipyardShipTypesInner && type == other.type;
  }
}
