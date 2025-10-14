/// Waypoint Modifier Symbol
/// The unique identifier of the modifier.
enum WaypointModifierSymbol {
  STRIPPED._('STRIPPED'),
  UNSTABLE._('UNSTABLE'),
  RADIATION_LEAK._('RADIATION_LEAK'),
  CRITICAL_LIMIT._('CRITICAL_LIMIT'),
  CIVIL_UNREST._('CIVIL_UNREST');

  const WaypointModifierSymbol._(this.value);

  /// Creates a WaypointModifierSymbol from a json string.
  factory WaypointModifierSymbol.fromJson(String json) {
    return WaypointModifierSymbol.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown WaypointModifierSymbol value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static WaypointModifierSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return WaypointModifierSymbol.fromJson(json);
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
