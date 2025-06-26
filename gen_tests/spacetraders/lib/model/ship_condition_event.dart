import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_condition_event_component_prop.dart';
import 'package:spacetraders/model/ship_condition_event_symbol_prop.dart';

@immutable
class ShipConditionEvent {
  const ShipConditionEvent({
    required this.symbol,
    required this.component,
    required this.name,
    required this.description,
  });

  factory ShipConditionEvent.fromJson(Map<String, dynamic> json) {
    return ShipConditionEvent(
      symbol: ShipConditionEventSymbolProp.fromJson(json['symbol'] as String),
      component: ShipConditionEventComponentProp.fromJson(
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

  final ShipConditionEventSymbolProp symbol;
  final ShipConditionEventComponentProp component;
  final String name;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'component': component.toJson(),
      'name': name,
      'description': description,
    };
  }

  @override
  int get hashCode => Object.hashAll([symbol, component, name, description]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipConditionEvent &&
        symbol == other.symbol &&
        component == other.component &&
        name == other.name &&
        description == other.description;
  }
}
