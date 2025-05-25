import 'package:openapi/api_helpers.dart';
import 'package:openapi/model/meta.dart';
import 'package:openapi/model/public_agent.dart';

class GetAgents200Response {
  GetAgents200Response({required this.meta, this.data = const []});

  factory GetAgents200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetAgents200Response(
      data:
          (json['data'] as List<dynamic>)
              .map<PublicAgent>(
                (e) => PublicAgent.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetAgents200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetAgents200Response.fromJson(json);
  }

  List<PublicAgent> data;
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
    return other is GetAgents200Response &&
        listsEqual(data, other.data) &&
        meta == other.meta;
  }
}
