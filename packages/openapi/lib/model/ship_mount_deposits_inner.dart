enum ShipMountDepositsInner {
  QUARTZ_SAND._('QUARTZ_SAND'),
  SILICON_CRYSTALS._('SILICON_CRYSTALS'),
  PRECIOUS_STONES._('PRECIOUS_STONES'),
  ICE_WATER._('ICE_WATER'),
  AMMONIA_ICE._('AMMONIA_ICE'),
  IRON_ORE._('IRON_ORE'),
  COPPER_ORE._('COPPER_ORE'),
  SILVER_ORE._('SILVER_ORE'),
  ALUMINUM_ORE._('ALUMINUM_ORE'),
  GOLD_ORE._('GOLD_ORE'),
  PLATINUM_ORE._('PLATINUM_ORE'),
  DIAMONDS._('DIAMONDS'),
  URANITE_ORE._('URANITE_ORE'),
  MERITIUM_ORE._('MERITIUM_ORE');

  const ShipMountDepositsInner._(this.value);

  /// Creates a ShipMountDepositsInner from a json string.
  factory ShipMountDepositsInner.fromJson(String json) {
    return ShipMountDepositsInner.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipMountDepositsInner value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipMountDepositsInner? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipMountDepositsInner.fromJson(json);
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
