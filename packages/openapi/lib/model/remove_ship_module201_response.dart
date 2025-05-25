import 'package:openapi/model/remove_ship_module201_response_data.dart';

class RemoveShipModule201Response {
  RemoveShipModule201Response({required this.data});

  factory RemoveShipModule201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RemoveShipModule201Response(
      data: RemoveShipModule201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RemoveShipModule201Response? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return RemoveShipModule201Response.fromJson(json);
  }

  RemoveShipModule201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
