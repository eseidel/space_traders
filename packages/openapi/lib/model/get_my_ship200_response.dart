import 'package:openapi/model/ship.dart';

class GetMyShip200Response {
  GetMyShip200Response({required this.data});

  factory GetMyShip200Response.fromJson(Map<String, dynamic> json) {
    return GetMyShip200Response(
      data: Ship.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetMyShip200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetMyShip200Response.fromJson(json);
  }

  final Ship data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
