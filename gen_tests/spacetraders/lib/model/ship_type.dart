enum ShipType {
  shipProbe._('SHIP_PROBE'),
  shipMiningDrone._('SHIP_MINING_DRONE'),
  shipSiphonDrone._('SHIP_SIPHON_DRONE'),
  shipInterceptor._('SHIP_INTERCEPTOR'),
  shipLightHauler._('SHIP_LIGHT_HAULER'),
  shipCommandFrigate._('SHIP_COMMAND_FRIGATE'),
  shipExplorer._('SHIP_EXPLORER'),
  shipHeavyFreighter._('SHIP_HEAVY_FREIGHTER'),
  shipLightShuttle._('SHIP_LIGHT_SHUTTLE'),
  shipOreHound._('SHIP_ORE_HOUND'),
  shipRefiningFreighter._('SHIP_REFINING_FREIGHTER'),
  shipSurveyor._('SHIP_SURVEYOR'),
  shipBulkFreighter._('SHIP_BULK_FREIGHTER');

  const ShipType._(this.value);

  factory ShipType.fromJson(String json) {
    return ShipType.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown ShipType value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipType? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipType.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
