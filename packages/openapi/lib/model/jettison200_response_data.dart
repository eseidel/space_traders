import 'package:openapi/model/ship_cargo.dart';

class Jettison200ResponseData {
  Jettison200ResponseData({required this.cargo});

  factory Jettison200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return Jettison200ResponseData(
      cargo: ShipCargo.fromJson(json['cargo'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Jettison200ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Jettison200ResponseData.fromJson(json);
  }

  ShipCargo cargo;

  Map<String, dynamic> toJson() {
    return {'cargo': cargo.toJson()};
  }

  @override
  int get hashCode => cargo.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Jettison200ResponseData && cargo == other.cargo;
  }
}
