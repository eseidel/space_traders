import 'package:openapi/model/ship_component_condition.dart';
import 'package:openapi/model/ship_component_integrity.dart';
import 'package:openapi/model/ship_component_quality.dart';
import 'package:openapi/model/ship_frame_symbol.dart';
import 'package:openapi/model/ship_requirements.dart';

class ShipFrame {
  ShipFrame({
    required this.symbol,
    required this.name,
    required this.condition,
    required this.integrity,
    required this.description,
    required this.moduleSlots,
    required this.mountingPoints,
    required this.fuelCapacity,
    required this.requirements,
    required this.quality,
  });

  factory ShipFrame.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipFrame(
      symbol: ShipFrameSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      condition: ShipComponentCondition((json['condition'] as num).toDouble()),
      integrity: ShipComponentIntegrity((json['integrity'] as num).toDouble()),
      description: json['description'] as String,
      moduleSlots: json['moduleSlots'] as int,
      mountingPoints: json['mountingPoints'] as int,
      fuelCapacity: json['fuelCapacity'] as int,
      requirements: ShipRequirements.fromJson(
        json['requirements'] as Map<String, dynamic>,
      ),
      quality: ShipComponentQuality((json['quality'] as num).toDouble()),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipFrame? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipFrame.fromJson(json);
  }

  ShipFrameSymbol symbol;
  String name;
  ShipComponentCondition condition;
  ShipComponentIntegrity integrity;
  String description;
  int moduleSlots;
  int mountingPoints;
  int fuelCapacity;
  ShipRequirements requirements;
  ShipComponentQuality quality;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'condition': condition.toJson(),
      'integrity': integrity.toJson(),
      'description': description,
      'moduleSlots': moduleSlots,
      'mountingPoints': mountingPoints,
      'fuelCapacity': fuelCapacity,
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
    moduleSlots,
    mountingPoints,
    fuelCapacity,
    requirements,
    quality,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipFrame &&
        symbol == other.symbol &&
        name == other.name &&
        condition == other.condition &&
        integrity == other.integrity &&
        description == other.description &&
        moduleSlots == other.moduleSlots &&
        mountingPoints == other.mountingPoints &&
        fuelCapacity == other.fuelCapacity &&
        requirements == other.requirements &&
        quality == other.quality;
  }
}
