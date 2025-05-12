import 'package:spacetraders/model/waypoint_trait_symbol.dart';

class WaypointTrait {
  WaypointTrait({
    required this.symbol,
    required this.name,
    required this.description,
  });

  factory WaypointTrait.fromJson(Map<String, dynamic> json) {
    return WaypointTrait(
      symbol: WaypointTraitSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  final WaypointTraitSymbol symbol;
  final String name;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'description': description,
    };
  }
}
