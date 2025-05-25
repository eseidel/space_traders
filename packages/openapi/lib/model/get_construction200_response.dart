import 'package:openapi/model/construction.dart';

class GetConstruction200Response {
  GetConstruction200Response({required this.data});

  factory GetConstruction200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetConstruction200Response(
      data: Construction.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetConstruction200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetConstruction200Response.fromJson(json);
  }

  Construction data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
