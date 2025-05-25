import 'package:openapi/model/waypoint_modifier_symbol.dart';

class WaypointModifier {
  WaypointModifier({
    required this.symbol,
    required this.name,
    required this.description,
  });

  factory WaypointModifier.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return WaypointModifier(
      symbol: WaypointModifierSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static WaypointModifier? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return WaypointModifier.fromJson(json);
  }

  WaypointModifierSymbol symbol;
  String name;
  String description;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'description': description,
    };
  }

  @override
  int get hashCode => Object.hash(symbol, name, description);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaypointModifier &&
        symbol == other.symbol &&
        name == other.name &&
        description == other.description;
  }
}
