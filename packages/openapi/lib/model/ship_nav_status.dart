/// The current status of the ship
enum ShipNavStatus {
  IN_TRANSIT._('IN_TRANSIT'),
  IN_ORBIT._('IN_ORBIT'),
  DOCKED._('DOCKED');

  const ShipNavStatus._(this.value);

  /// Creates a ShipNavStatus from a json string.
  factory ShipNavStatus.fromJson(String json) {
    return ShipNavStatus.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown ShipNavStatus value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipNavStatus? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipNavStatus.fromJson(json);
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
