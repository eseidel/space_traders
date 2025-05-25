import 'package:openapi/model/shipyard.dart';

class GetShipyard200Response {
  GetShipyard200Response({required this.data});

  factory GetShipyard200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetShipyard200Response(
      data: Shipyard.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetShipyard200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetShipyard200Response.fromJson(json);
  }

  Shipyard data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetShipyard200Response && data == other.data;
  }
}
