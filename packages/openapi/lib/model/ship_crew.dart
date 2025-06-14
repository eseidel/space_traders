import 'package:openapi/model/ship_crew_rotation.dart';

class ShipCrew {
  ShipCrew({
    required this.current,
    required this.required_,
    required this.capacity,
    required this.morale,
    required this.wages,
    this.rotation = ShipCrewRotation.STRICT,
  });

  factory ShipCrew.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipCrew(
      current: json['current'] as int,
      required_: json['required'] as int,
      capacity: json['capacity'] as int,
      rotation: ShipCrewRotation.fromJson(json['rotation'] as String),
      morale: json['morale'] as int,
      wages: json['wages'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipCrew? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipCrew.fromJson(json);
  }

  int current;
  int required_;
  int capacity;
  ShipCrewRotation rotation;
  int morale;
  int wages;

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'required': required_,
      'capacity': capacity,
      'rotation': rotation.toJson(),
      'morale': morale,
      'wages': wages,
    };
  }

  @override
  int get hashCode =>
      Object.hash(current, required_, capacity, rotation, morale, wages);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipCrew &&
        current == other.current &&
        required_ == other.required_ &&
        capacity == other.capacity &&
        rotation == other.rotation &&
        morale == other.morale &&
        wages == other.wages;
  }
}
