enum WaypointType {
  planet._('PLANET'),
  gasGiant._('GAS_GIANT'),
  moon._('MOON'),
  orbitalStation._('ORBITAL_STATION'),
  jumpGate._('JUMP_GATE'),
  asteroidField._('ASTEROID_FIELD'),
  asteroid._('ASTEROID'),
  engineeredAsteroid._('ENGINEERED_ASTEROID'),
  asteroidBase._('ASTEROID_BASE'),
  nebula._('NEBULA'),
  debrisField._('DEBRIS_FIELD'),
  gravityWell._('GRAVITY_WELL'),
  artificialGravityWell._('ARTIFICIAL_GRAVITY_WELL'),
  fuelStation._('FUEL_STATION');

  const WaypointType._(this.value);

  factory WaypointType.fromJson(String json) {
    return WaypointType.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown WaypointType value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static WaypointType? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return WaypointType.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
