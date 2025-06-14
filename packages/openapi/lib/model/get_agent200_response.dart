import 'package:openapi/model/public_agent.dart';

class GetAgent200Response {
  GetAgent200Response({required this.data});

  factory GetAgent200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetAgent200Response(
      data: PublicAgent.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetAgent200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetAgent200Response.fromJson(json);
  }

  PublicAgent data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetAgent200Response && data == other.data;
  }
}
