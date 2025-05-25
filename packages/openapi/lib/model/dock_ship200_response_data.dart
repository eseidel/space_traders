import 'package:openapi/model/ship_nav.dart';

class DockShip200ResponseData {
  DockShip200ResponseData({required this.nav});

  factory DockShip200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return DockShip200ResponseData(
      nav: ShipNav.fromJson(json['nav'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static DockShip200ResponseData? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return DockShip200ResponseData.fromJson(json);
  }

  ShipNav nav;

  Map<String, dynamic> toJson() {
    return {'nav': nav.toJson()};
  }
}
