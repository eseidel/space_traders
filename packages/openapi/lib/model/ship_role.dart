/// The registered role of the ship
enum ShipRole {
  FABRICATOR._('FABRICATOR'),
  HARVESTER._('HARVESTER'),
  HAULER._('HAULER'),
  INTERCEPTOR._('INTERCEPTOR'),
  EXCAVATOR._('EXCAVATOR'),
  TRANSPORT._('TRANSPORT'),
  REPAIR._('REPAIR'),
  SURVEYOR._('SURVEYOR'),
  COMMAND._('COMMAND'),
  CARRIER._('CARRIER'),
  PATROL._('PATROL'),
  SATELLITE._('SATELLITE'),
  EXPLORER._('EXPLORER'),
  REFINERY._('REFINERY');

  const ShipRole._(this.value);

  /// Creates a ShipRole from a json string.
  factory ShipRole.fromJson(String json) {
    return ShipRole.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown ShipRole value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRole? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipRole.fromJson(json);
  }

  /// The value of the enum, as a string.  This is the exact value
  /// from the OpenAPI spec and will be used for network transport.
  final String value;

  /// Converts the enum to a json string.
  String toJson() => value;

  /// Returns the string value of the enum.
  @override
  String toString() => value;
}
