import 'package:openapi/model/ship_cargo.dart';

class GetMyShipCargo200Response {
  GetMyShipCargo200Response({required this.data});

  factory GetMyShipCargo200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetMyShipCargo200Response(
      data: ShipCargo.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMyShipCargo200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetMyShipCargo200Response.fromJson(json);
  }

  ShipCargo data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetMyShipCargo200Response && data == other.data;
  }
}
