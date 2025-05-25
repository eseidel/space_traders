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
      condition: json['condition'] as double,
      integrity: json['integrity'] as double,
      description: json['description'] as String,
      moduleSlots: json['moduleSlots'] as int,
      mountingPoints: json['mountingPoints'] as int,
      fuelCapacity: json['fuelCapacity'] as int,
      requirements: ShipRequirements.fromJson(
        json['requirements'] as Map<String, dynamic>,
      ),
      quality: json['quality'] as double,
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
  double condition;
  double integrity;
  String description;
  int moduleSlots;
  int mountingPoints;
  int fuelCapacity;
  ShipRequirements requirements;
  double quality;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'condition': condition,
      'integrity': integrity,
      'description': description,
      'moduleSlots': moduleSlots,
      'mountingPoints': mountingPoints,
      'fuelCapacity': fuelCapacity,
      'requirements': requirements.toJson(),
      'quality': quality,
    };
  }
}
