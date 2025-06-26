import 'package:meta/meta.dart';

@immutable
class ScannedShipMountsPropInner {
  const ScannedShipMountsPropInner({required this.symbol});

  factory ScannedShipMountsPropInner.fromJson(Map<String, dynamic> json) {
    return ScannedShipMountsPropInner(symbol: json['symbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScannedShipMountsPropInner? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScannedShipMountsPropInner.fromJson(json);
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
    return other is ScannedShipMountsPropInner && symbol == other.symbol;
  }
}
