enum ShipMountSymbol {
  mountGasSiphonI._('MOUNT_GAS_SIPHON_I'),
  mountGasSiphonIi._('MOUNT_GAS_SIPHON_II'),
  mountGasSiphonIii._('MOUNT_GAS_SIPHON_III'),
  mountSurveyorI._('MOUNT_SURVEYOR_I'),
  mountSurveyorIi._('MOUNT_SURVEYOR_II'),
  mountSurveyorIii._('MOUNT_SURVEYOR_III'),
  mountSensorArrayI._('MOUNT_SENSOR_ARRAY_I'),
  mountSensorArrayIi._('MOUNT_SENSOR_ARRAY_II'),
  mountSensorArrayIii._('MOUNT_SENSOR_ARRAY_III'),
  mountMiningLaserI._('MOUNT_MINING_LASER_I'),
  mountMiningLaserIi._('MOUNT_MINING_LASER_II'),
  mountMiningLaserIii._('MOUNT_MINING_LASER_III'),
  mountLaserCannonI._('MOUNT_LASER_CANNON_I'),
  mountMissileLauncherI._('MOUNT_MISSILE_LAUNCHER_I'),
  mountTurretI._('MOUNT_TURRET_I');

  const ShipMountSymbol._(this.value);

  factory ShipMountSymbol.fromJson(String json) {
    return ShipMountSymbol.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ShipMountSymbol value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipMountSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipMountSymbol.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
