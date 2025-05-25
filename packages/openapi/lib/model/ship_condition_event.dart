import 'package:openapi/model/ship_condition_event_component.dart';
import 'package:openapi/model/ship_condition_event_symbol.dart';

class ShipConditionEvent {
  ShipConditionEvent({
    required this.symbol,
    required this.component,
    required this.name,
    required this.description,
  });

  factory ShipConditionEvent.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipConditionEvent(
      symbol: ShipConditionEventSymbol.fromJson(json['symbol'] as String),
      component: ShipConditionEventComponent.fromJson(
        json['component'] as String,
      ),
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipConditionEvent? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipConditionEvent.fromJson(json);
  }

  ShipConditionEventSymbol symbol;
  ShipConditionEventComponent component;
  String name;
  String description;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'component': component.toJson(),
      'name': name,
      'description': description,
    };
  }
}
