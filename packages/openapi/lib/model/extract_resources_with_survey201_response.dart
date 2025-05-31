import 'package:openapi/model/extract_resources_with_survey201_response_data.dart';

class ExtractResourcesWithSurvey201Response {
  ExtractResourcesWithSurvey201Response({required this.data});

  factory ExtractResourcesWithSurvey201Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ExtractResourcesWithSurvey201Response(
      data: ExtractResourcesWithSurvey201ResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ExtractResourcesWithSurvey201Response? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ExtractResourcesWithSurvey201Response.fromJson(json);
  }

  ExtractResourcesWithSurvey201ResponseData data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtractResourcesWithSurvey201Response && data == other.data;
  }
}
