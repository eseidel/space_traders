import 'package:openapi/model/faction.dart';

class GetFaction200Response {
  GetFaction200Response({required this.data});

  factory GetFaction200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetFaction200Response(
      data: Faction.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetFaction200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetFaction200Response.fromJson(json);
  }

  Faction data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}
