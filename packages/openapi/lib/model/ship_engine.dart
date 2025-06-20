import 'package:openapi/model/ship_component_condition.dart';
import 'package:openapi/model/ship_component_integrity.dart';
import 'package:openapi/model/ship_component_quality.dart';
import 'package:openapi/model/ship_engine_symbol.dart';
import 'package:openapi/model/ship_requirements.dart';

class ShipEngine {
  ShipEngine({
    required this.symbol,
    required this.name,
    required this.condition,
    required this.integrity,
    required this.description,
    required this.speed,
    required this.requirements,
    required this.quality,
  });

  factory ShipEngine.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipEngine(
      symbol: ShipEngineSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      condition: ShipComponentCondition((json['condition'] as num).toDouble()),
      integrity: ShipComponentIntegrity((json['integrity'] as num).toDouble()),
      description: json['description'] as String,
      speed: json['speed'] as int,
      requirements: ShipRequirements.fromJson(
        json['requirements'] as Map<String, dynamic>,
      ),
      quality: ShipComponentQuality((json['quality'] as num).toDouble()),
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

  ShipEngineSymbol symbol;
  String name;
  ShipComponentCondition condition;
  ShipComponentIntegrity integrity;
  String description;
  int speed;
  ShipRequirements requirements;
  ShipComponentQuality quality;

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
  int get hashCode => Object.hash(
    symbol,
    name,
    condition,
    integrity,
    description,
    speed,
    requirements,
    quality,
  );

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
