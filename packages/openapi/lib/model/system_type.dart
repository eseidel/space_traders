/// The type of system.
enum SystemType {
  NEUTRON_STAR._('NEUTRON_STAR'),
  RED_STAR._('RED_STAR'),
  ORANGE_STAR._('ORANGE_STAR'),
  BLUE_STAR._('BLUE_STAR'),
  YOUNG_STAR._('YOUNG_STAR'),
  WHITE_DWARF._('WHITE_DWARF'),
  BLACK_HOLE._('BLACK_HOLE'),
  HYPERGIANT._('HYPERGIANT'),
  NEBULA._('NEBULA'),
  UNSTABLE._('UNSTABLE');

  const SystemType._(this.value);

  /// Creates a SystemType from a json string.
  factory SystemType.fromJson(String json) {
    return SystemType.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown SystemType value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SystemType? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return SystemType.fromJson(json);
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
