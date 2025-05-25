import 'package:openapi/model/system_type.dart';

class ScannedSystem {
  ScannedSystem({
    required this.symbol,
    required this.sectorSymbol,
    required this.type,
    required this.x,
    required this.y,
    required this.distance,
  });

  factory ScannedSystem.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ScannedSystem(
      symbol: json['symbol'] as String,
      sectorSymbol: json['sectorSymbol'] as String,
      type: SystemType.fromJson(json['type'] as String),
      x: json['x'] as int,
      y: json['y'] as int,
      distance: json['distance'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScannedSystem? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScannedSystem.fromJson(json);
  }

  String symbol;
  String sectorSymbol;
  SystemType type;
  int x;
  int y;
  int distance;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'sectorSymbol': sectorSymbol,
      'type': type.toJson(),
      'x': x,
      'y': y,
      'distance': distance,
    };
  }
}
