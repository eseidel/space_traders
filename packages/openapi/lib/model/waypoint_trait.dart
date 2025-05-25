import 'package:openapi/model/waypoint_trait_symbol.dart';

class WaypointTrait {
  WaypointTrait({
    required this.symbol,
    required this.name,
    required this.description,
  });

  factory WaypointTrait.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return WaypointTrait(
      symbol: WaypointTraitSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static WaypointTrait? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return WaypointTrait.fromJson(json);
  }

  WaypointTraitSymbol symbol;
  String name;
  String description;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'description': description,
    };
  }
}
