import 'package:openapi/model/meta.dart';
import 'package:openapi/model/system.dart';

class GetSystems200Response {
  GetSystems200Response({required this.data, required this.meta});

  factory GetSystems200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetSystems200Response(
      data:
          (json['data'] as List<dynamic>)
              .map<System>((e) => System.fromJson(e as Map<String, dynamic>))
              .toList(),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetSystems200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetSystems200Response.fromJson(json);
  }

  List<System> data;
  Meta meta;

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }
}
