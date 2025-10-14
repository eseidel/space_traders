/// Symbol of this mount.
enum ShipMountSymbol {
  GAS_SIPHON_I._('MOUNT_GAS_SIPHON_I'),
  GAS_SIPHON_II._('MOUNT_GAS_SIPHON_II'),
  GAS_SIPHON_III._('MOUNT_GAS_SIPHON_III'),
  SURVEYOR_I._('MOUNT_SURVEYOR_I'),
  SURVEYOR_II._('MOUNT_SURVEYOR_II'),
  SURVEYOR_III._('MOUNT_SURVEYOR_III'),
  SENSOR_ARRAY_I._('MOUNT_SENSOR_ARRAY_I'),
  SENSOR_ARRAY_II._('MOUNT_SENSOR_ARRAY_II'),
  SENSOR_ARRAY_III._('MOUNT_SENSOR_ARRAY_III'),
  MINING_LASER_I._('MOUNT_MINING_LASER_I'),
  MINING_LASER_II._('MOUNT_MINING_LASER_II'),
  MINING_LASER_III._('MOUNT_MINING_LASER_III'),
  LASER_CANNON_I._('MOUNT_LASER_CANNON_I'),
  MISSILE_LAUNCHER_I._('MOUNT_MISSILE_LAUNCHER_I'),
  TURRET_I._('MOUNT_TURRET_I');

  const ShipMountSymbol._(this.value);

  /// Creates a ShipMountSymbol from a json string.
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

  /// The value of the enum, as a string.  This is the exact value
  /// from the OpenAPI spec and will be used for network transport.
  final String value;

  /// Converts the enum to a json string.
  String toJson() => value;

  /// Returns the string value of the enum.
  @override
  String toString() => value;
}
