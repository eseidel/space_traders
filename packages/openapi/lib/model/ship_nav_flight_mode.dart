/// The ship's set speed when traveling between waypoints or systems.
enum ShipNavFlightMode {
  DRIFT._('DRIFT'),
  STEALTH._('STEALTH'),
  CRUISE._('CRUISE'),
  BURN._('BURN');

  const ShipNavFlightMode._(this.value);

  /// Creates a ShipNavFlightMode from a json string.
  factory ShipNavFlightMode.fromJson(String json) {
    return ShipNavFlightMode.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipNavFlightMode value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipNavFlightMode? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipNavFlightMode.fromJson(json);
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
