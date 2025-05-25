import 'package:openapi/model/remove_mount201_response_data.dart';

class RemoveMount201Response {
  RemoveMount201Response({required this.data});

  factory RemoveMount201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RemoveMount201Response(
      data: RemoveMount201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RemoveMount201Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RemoveMount201Response.fromJson(json);
  }

  RemoveMount201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
