import 'package:openapi/model/cooldown.dart';

class GetShipCooldown200Response {
  GetShipCooldown200Response({required this.data});

  factory GetShipCooldown200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetShipCooldown200Response(
      data: Cooldown.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetShipCooldown200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetShipCooldown200Response.fromJson(json);
  }

  Cooldown data;

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetShipCooldown200Response && data == other.data;
  }
}
