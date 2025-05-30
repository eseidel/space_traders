import 'package:openapi/model/ship_nav_flight_mode.dart';

class PatchShipNavRequest {
  PatchShipNavRequest({this.flightMode = ShipNavFlightMode.CRUISE});

  factory PatchShipNavRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return PatchShipNavRequest(
      flightMode: ShipNavFlightMode.maybeFromJson(
        (json['flightMode'] as String?) ?? ShipNavFlightMode.CRUISE,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PatchShipNavRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PatchShipNavRequest.fromJson(json);
  }

  ShipNavFlightMode flightMode;

  Map<String, dynamic> toJson() {
    return {'flightMode': flightMode.toJson()};
  }

  @override
  int get hashCode => flightMode.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatchShipNavRequest && flightMode == other.flightMode;
  }
}
