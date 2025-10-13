/// The supply level of a trade good.
enum SupplyLevel {
  SCARCE._('SCARCE'),
  LIMITED._('LIMITED'),
  MODERATE._('MODERATE'),
  HIGH._('HIGH'),
  ABUNDANT._('ABUNDANT');

  const SupplyLevel._(this.value);

  /// Creates a SupplyLevel from a json string.
  factory SupplyLevel.fromJson(String json) {
    return SupplyLevel.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown SupplyLevel value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SupplyLevel? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return SupplyLevel.fromJson(json);
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
