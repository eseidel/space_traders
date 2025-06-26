import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_type.dart';

@immutable
class ShipyardShipTypesPropInner {
  const ShipyardShipTypesPropInner({required this.type});

  factory ShipyardShipTypesPropInner.fromJson(Map<String, dynamic> json) {
    return ShipyardShipTypesPropInner(
      type: ShipType.fromJson(json['type'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipyardShipTypesPropInner? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipyardShipTypesPropInner.fromJson(json);
  }

  final ShipType type;

  Map<String, dynamic> toJson() {
    return {'type': type.toJson()};
  }

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipyardShipTypesPropInner && type == other.type;
  }
}
