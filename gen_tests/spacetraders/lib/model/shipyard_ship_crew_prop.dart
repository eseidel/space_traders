import 'package:meta/meta.dart';

@immutable
class ShipyardShipCrewProp {
  const ShipyardShipCrewProp({required this.required_, required this.capacity});

  factory ShipyardShipCrewProp.fromJson(Map<String, dynamic> json) {
    return ShipyardShipCrewProp(
      required_: json['required'] as int,
      capacity: json['capacity'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipyardShipCrewProp? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipyardShipCrewProp.fromJson(json);
  }

  final int required_;
  final int capacity;

  Map<String, dynamic> toJson() {
    return {'required': required_, 'capacity': capacity};
  }

  @override
  int get hashCode => Object.hashAll([required_, capacity]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipyardShipCrewProp &&
        required_ == other.required_ &&
        capacity == other.capacity;
  }
}
