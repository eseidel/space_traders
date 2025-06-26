enum ShipReactorSymbolProp {
  reactorSolarI._('REACTOR_SOLAR_I'),
  reactorFusionI._('REACTOR_FUSION_I'),
  reactorFissionI._('REACTOR_FISSION_I'),
  reactorChemicalI._('REACTOR_CHEMICAL_I'),
  reactorAntimatterI._('REACTOR_ANTIMATTER_I');

  const ShipReactorSymbolProp._(this.value);

  factory ShipReactorSymbolProp.fromJson(String json) {
    return ShipReactorSymbolProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipReactorSymbolProp value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipReactorSymbolProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipReactorSymbolProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
