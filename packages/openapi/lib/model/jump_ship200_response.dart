import 'package:openapi/model/jump_ship200_response_data.dart';

class JumpShip200Response {
  JumpShip200Response({required this.data});

  factory JumpShip200Response.fromJson(Map<String, dynamic> json) {
    return JumpShip200Response(
      data: JumpShip200ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static JumpShip200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return JumpShip200Response.fromJson(json);
  }

  final JumpShip200ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
