import 'package:openapi/model/waypoint.dart';

class GetWaypoint200Response {
  GetWaypoint200Response({required this.data});

  factory GetWaypoint200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetWaypoint200Response(
      data: Waypoint.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetWaypoint200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetWaypoint200Response.fromJson(json);
  }

  Waypoint data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
