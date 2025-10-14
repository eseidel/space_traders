enum ShipConditionEventComponent {
  FRAME._('FRAME'),
  REACTOR._('REACTOR'),
  ENGINE._('ENGINE');

  const ShipConditionEventComponent._(this.value);

  /// Creates a ShipConditionEventComponent from a json string.
  factory ShipConditionEventComponent.fromJson(String json) {
    return ShipConditionEventComponent.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown ShipConditionEventComponent value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipConditionEventComponent? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipConditionEventComponent.fromJson(json);
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
