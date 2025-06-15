import 'package:meta/meta.dart';
import 'package:spacetraders/model/ship_crew_rotation.dart';

@immutable
class ShipCrew {
  const ShipCrew({
    required this.current,
    required this.required_,
    required this.capacity,
    required this.morale,
    required this.wages,
    this.rotation = ShipCrewRotation.strict,
  });

  factory ShipCrew.fromJson(Map<String, dynamic> json) {
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

  final int current;
  final int required_;
  final int capacity;
  final ShipCrewRotation rotation;
  final int morale;
  final int wages;

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
