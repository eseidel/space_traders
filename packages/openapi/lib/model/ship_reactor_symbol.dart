/// Symbol of the reactor.
enum ShipReactorSymbol {
  SOLAR_I._('REACTOR_SOLAR_I'),
  FUSION_I._('REACTOR_FUSION_I'),
  FISSION_I._('REACTOR_FISSION_I'),
  CHEMICAL_I._('REACTOR_CHEMICAL_I'),
  ANTIMATTER_I._('REACTOR_ANTIMATTER_I');

  const ShipReactorSymbol._(this.value);

  /// Creates a ShipReactorSymbol from a json string.
  factory ShipReactorSymbol.fromJson(String json) {
    return ShipReactorSymbol.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipReactorSymbol value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipReactorSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipReactorSymbol.fromJson(json);
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
