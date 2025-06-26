enum ShipEngineSymbolProp {
  engineImpulseDriveI._('ENGINE_IMPULSE_DRIVE_I'),
  engineIonDriveI._('ENGINE_ION_DRIVE_I'),
  engineIonDriveIi._('ENGINE_ION_DRIVE_II'),
  engineHyperDriveI._('ENGINE_HYPER_DRIVE_I');

  const ShipEngineSymbolProp._(this.value);

  factory ShipEngineSymbolProp.fromJson(String json) {
    return ShipEngineSymbolProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipEngineSymbolProp value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipEngineSymbolProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipEngineSymbolProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
