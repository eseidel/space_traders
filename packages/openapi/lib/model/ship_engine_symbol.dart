/// The symbol of the engine.
enum ShipEngineSymbol {
  IMPULSE_DRIVE_I._('ENGINE_IMPULSE_DRIVE_I'),
  ION_DRIVE_I._('ENGINE_ION_DRIVE_I'),
  ION_DRIVE_II._('ENGINE_ION_DRIVE_II'),
  HYPER_DRIVE_I._('ENGINE_HYPER_DRIVE_I');

  const ShipEngineSymbol._(this.value);

  /// Creates a ShipEngineSymbol from a json string.
  factory ShipEngineSymbol.fromJson(String json) {
    return ShipEngineSymbol.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipEngineSymbol value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipEngineSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipEngineSymbol.fromJson(json);
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
