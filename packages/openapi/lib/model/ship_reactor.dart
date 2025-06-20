import 'package:openapi/model/ship_component_condition.dart';
import 'package:openapi/model/ship_component_integrity.dart';
import 'package:openapi/model/ship_component_quality.dart';
import 'package:openapi/model/ship_reactor_symbol.dart';
import 'package:openapi/model/ship_requirements.dart';

class ShipReactor {
  ShipReactor({
    required this.symbol,
    required this.name,
    required this.condition,
    required this.integrity,
    required this.description,
    required this.powerOutput,
    required this.requirements,
    required this.quality,
  });

  factory ShipReactor.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipReactor(
      symbol: ShipReactorSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      condition: ShipComponentCondition((json['condition'] as num).toDouble()),
      integrity: ShipComponentIntegrity((json['integrity'] as num).toDouble()),
      description: json['description'] as String,
      powerOutput: json['powerOutput'] as int,
      requirements: ShipRequirements.fromJson(
        json['requirements'] as Map<String, dynamic>,
      ),
      quality: ShipComponentQuality((json['quality'] as num).toDouble()),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipReactor? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipReactor.fromJson(json);
  }

  ShipReactorSymbol symbol;
  String name;
  ShipComponentCondition condition;
  ShipComponentIntegrity integrity;
  String description;
  int powerOutput;
  ShipRequirements requirements;
  ShipComponentQuality quality;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'condition': condition.toJson(),
      'integrity': integrity.toJson(),
      'description': description,
      'powerOutput': powerOutput,
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
    powerOutput,
    requirements,
    quality,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipReactor &&
        symbol == other.symbol &&
        name == other.name &&
        condition == other.condition &&
        integrity == other.integrity &&
        description == other.description &&
        powerOutput == other.powerOutput &&
        requirements == other.requirements &&
        quality == other.quality;
  }
}
