import 'package:openapi/model/ship_nav.dart';

class GetShipNav200Response {
  GetShipNav200Response({required this.data});

  factory GetShipNav200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetShipNav200Response(
      data: ShipNav.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetShipNav200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetShipNav200Response.fromJson(json);
  }

  ShipNav data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetShipNav200Response && data == other.data;
  }
}
