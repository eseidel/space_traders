import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_component_condition.dart';
import 'package:spacetraders/model/ship_component_integrity.dart';
import 'package:spacetraders/model/ship_component_quality.dart';
import 'package:spacetraders/model/ship_engine_symbol.dart';
import 'package:spacetraders/model/ship_requirements.dart';

@immutable
class ShipEngine {
  const ShipEngine({
    required this.symbol,
    required this.name,
    required this.condition,
    required this.integrity,
    required this.description,
    required this.speed,
    required this.requirements,
    required this.quality,
  });

  factory ShipEngine.fromJson(Map<String, dynamic> json) {
    return ShipEngine(
      symbol: ShipEngineSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      condition: ShipComponentCondition.fromJson(json['condition'] as num),
      integrity: ShipComponentIntegrity.fromJson(json['integrity'] as num),
      description: json['description'] as String,
      speed: json['speed'] as int,
      requirements: ShipRequirements.fromJson(
        json['requirements'] as Map<String, dynamic>,
      ),
      quality: ShipComponentQuality.fromJson(json['quality'] as num),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipEngine? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipEngine.fromJson(json);
  }

  final ShipEngineSymbol symbol;
  final String name;
  final ShipComponentCondition condition;
  final ShipComponentIntegrity integrity;
  final String description;
  final int speed;
  final ShipRequirements requirements;
  final ShipComponentQuality quality;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'condition': condition.toJson(),
      'integrity': integrity.toJson(),
      'description': description,
      'speed': speed,
      'requirements': requirements.toJson(),
      'quality': quality.toJson(),
    };
  }

  @override
  int get hashCode => Object.hashAll([
    symbol,
    name,
    condition,
    integrity,
    description,
    speed,
    requirements,
    quality,
  ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipEngine &&
        symbol == other.symbol &&
        name == other.name &&
        condition == other.condition &&
        integrity == other.integrity &&
        description == other.description &&
        speed == other.speed &&
        requirements == other.requirements &&
        quality == other.quality;
  }
}
