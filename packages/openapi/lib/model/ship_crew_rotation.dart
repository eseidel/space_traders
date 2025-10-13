/// The rotation of crew shifts. A stricter shift improves the ship's
/// performance. A more relaxed shift improves the crew's morale.
enum ShipCrewRotation {
  STRICT._('STRICT'),
  RELAXED._('RELAXED');

  const ShipCrewRotation._(this.value);

  /// Creates a ShipCrewRotation from a json string.
  factory ShipCrewRotation.fromJson(String json) {
    return ShipCrewRotation.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipCrewRotation value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipCrewRotation? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipCrewRotation.fromJson(json);
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
