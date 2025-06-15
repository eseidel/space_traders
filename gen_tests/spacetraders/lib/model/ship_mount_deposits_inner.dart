enum ShipMountDepositsInner {
  quartzSand._('QUARTZ_SAND'),
  siliconCrystals._('SILICON_CRYSTALS'),
  preciousStones._('PRECIOUS_STONES'),
  iceWater._('ICE_WATER'),
  ammoniaIce._('AMMONIA_ICE'),
  ironOre._('IRON_ORE'),
  copperOre._('COPPER_ORE'),
  silverOre._('SILVER_ORE'),
  aluminumOre._('ALUMINUM_ORE'),
  goldOre._('GOLD_ORE'),
  platinumOre._('PLATINUM_ORE'),
  diamonds._('DIAMONDS'),
  uraniteOre._('URANITE_ORE'),
  meritiumOre._('MERITIUM_ORE');

  const ShipMountDepositsInner._(this.value);

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

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
