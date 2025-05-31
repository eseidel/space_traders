import 'package:openapi/model/ship_type.dart';

class PurchaseShipRequest {
  PurchaseShipRequest({required this.shipType, required this.waypointSymbol});

  factory PurchaseShipRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return PurchaseShipRequest(
      shipType: ShipType.fromJson(json['shipType'] as String),
      waypointSymbol: json['waypointSymbol'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PurchaseShipRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PurchaseShipRequest.fromJson(json);
  }

  ShipType shipType;
  String waypointSymbol;

  Map<String, dynamic> toJson() {
    return {'shipType': shipType.toJson(), 'waypointSymbol': waypointSymbol};
  }

  @override
  int get hashCode => Object.hash(shipType, waypointSymbol);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseShipRequest &&
        shipType == other.shipType &&
        waypointSymbol == other.waypointSymbol;
  }
}
