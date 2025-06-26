import 'package:meta/meta.dart';

@immutable
class ScannedShipReactorProp {
  const ScannedShipReactorProp({required this.symbol});

  factory ScannedShipReactorProp.fromJson(Map<String, dynamic> json) {
    return ScannedShipReactorProp(symbol: json['symbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScannedShipReactorProp? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScannedShipReactorProp.fromJson(json);
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
    return other is ScannedShipReactorProp && symbol == other.symbol;
  }
}
