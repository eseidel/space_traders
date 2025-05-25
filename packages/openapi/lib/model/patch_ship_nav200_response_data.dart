import 'package:openapi/model/ship_condition_event.dart';
import 'package:openapi/model/ship_fuel.dart';
import 'package:openapi/model/ship_nav.dart';

class PatchShipNav200ResponseData {
  PatchShipNav200ResponseData({
    required this.nav,
    required this.fuel,
    required this.events,
  });

  factory PatchShipNav200ResponseData.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return PatchShipNav200ResponseData(
      nav: ShipNav.fromJson(json['nav'] as Map<String, dynamic>),
      fuel: ShipFuel.fromJson(json['fuel'] as Map<String, dynamic>),
      events:
          (json['events'] as List<dynamic>)
              .map<ShipConditionEvent>(
                (e) => ShipConditionEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static PatchShipNav200ResponseData? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return PatchShipNav200ResponseData.fromJson(json);
  }

  ShipNav nav;
  ShipFuel fuel;
  List<ShipConditionEvent> events;

  Map<String, dynamic> toJson() {
    return {
      'nav': nav.toJson(),
      'fuel': fuel.toJson(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}
