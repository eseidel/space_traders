import 'package:meta/meta.dart';

@immutable
class ScannedShipFrameProp {
  const ScannedShipFrameProp({required this.symbol});

  factory ScannedShipFrameProp.fromJson(Map<String, dynamic> json) {
    return ScannedShipFrameProp(symbol: json['symbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScannedShipFrameProp? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScannedShipFrameProp.fromJson(json);
  }

  final String symbol;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol};
  }

  @override
  int get hashCode => symbol.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannedShipFrameProp && symbol == other.symbol;
  }
}
