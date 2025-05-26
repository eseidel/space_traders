import 'package:openapi/model/meta.dart';
import 'package:openapi/model/system.dart';
import 'package:openapi/model_helpers.dart';

class GetSystems200Response {
  GetSystems200Response({required this.meta, this.data = const []});

  factory GetSystems200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetSystems200Response(
      data:
          (json['data'] as List)
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

  @override
  int get hashCode => Object.hash(data, meta);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetSystems200Response &&
        listsEqual(data, other.data) &&
        meta == other.meta;
  }
}
