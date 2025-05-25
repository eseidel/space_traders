import 'package:openapi/model/extract_resources201_response_data.dart';

class ExtractResources201Response {
  ExtractResources201Response({required this.data});

  factory ExtractResources201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ExtractResources201Response(
      data: ExtractResources201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ExtractResources201Response? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ExtractResources201Response.fromJson(json);
  }

  ExtractResources201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtractResources201Response && data == other.data;
  }
}
