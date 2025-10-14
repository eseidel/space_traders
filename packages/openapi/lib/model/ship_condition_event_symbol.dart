/// The symbol of the event that occurred.
enum ShipConditionEventSymbol {
  REACTOR_OVERLOAD._('REACTOR_OVERLOAD'),
  ENERGY_SPIKE_FROM_MINERAL._('ENERGY_SPIKE_FROM_MINERAL'),
  SOLAR_FLARE_INTERFERENCE._('SOLAR_FLARE_INTERFERENCE'),
  COOLANT_LEAK._('COOLANT_LEAK'),
  POWER_DISTRIBUTION_FLUCTUATION._('POWER_DISTRIBUTION_FLUCTUATION'),
  MAGNETIC_FIELD_DISRUPTION._('MAGNETIC_FIELD_DISRUPTION'),
  HULL_MICROMETEORITE_STRIKES._('HULL_MICROMETEORITE_STRIKES'),
  STRUCTURAL_STRESS_FRACTURES._('STRUCTURAL_STRESS_FRACTURES'),
  CORROSIVE_MINERAL_CONTAMINATION._('CORROSIVE_MINERAL_CONTAMINATION'),
  THERMAL_EXPANSION_MISMATCH._('THERMAL_EXPANSION_MISMATCH'),
  VIBRATION_DAMAGE_FROM_DRILLING._('VIBRATION_DAMAGE_FROM_DRILLING'),
  ELECTROMAGNETIC_FIELD_INTERFERENCE._('ELECTROMAGNETIC_FIELD_INTERFERENCE'),
  IMPACT_WITH_EXTRACTED_DEBRIS._('IMPACT_WITH_EXTRACTED_DEBRIS'),
  FUEL_EFFICIENCY_DEGRADATION._('FUEL_EFFICIENCY_DEGRADATION'),
  COOLANT_SYSTEM_AGEING._('COOLANT_SYSTEM_AGEING'),
  DUST_MICROABRASIONS._('DUST_MICROABRASIONS'),
  THRUSTER_NOZZLE_WEAR._('THRUSTER_NOZZLE_WEAR'),
  EXHAUST_PORT_CLOGGING._('EXHAUST_PORT_CLOGGING'),
  BEARING_LUBRICATION_FADE._('BEARING_LUBRICATION_FADE'),
  SENSOR_CALIBRATION_DRIFT._('SENSOR_CALIBRATION_DRIFT'),
  HULL_MICROMETEORITE_DAMAGE._('HULL_MICROMETEORITE_DAMAGE'),
  SPACE_DEBRIS_COLLISION._('SPACE_DEBRIS_COLLISION'),
  THERMAL_STRESS._('THERMAL_STRESS'),
  VIBRATION_OVERLOAD._('VIBRATION_OVERLOAD'),
  PRESSURE_DIFFERENTIAL_STRESS._('PRESSURE_DIFFERENTIAL_STRESS'),
  ELECTROMAGNETIC_SURGE_EFFECTS._('ELECTROMAGNETIC_SURGE_EFFECTS'),
  ATMOSPHERIC_ENTRY_HEAT._('ATMOSPHERIC_ENTRY_HEAT');

  const ShipConditionEventSymbol._(this.value);

  /// Creates a ShipConditionEventSymbol from a json string.
  factory ShipConditionEventSymbol.fromJson(String json) {
    return ShipConditionEventSymbol.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown ShipConditionEventSymbol value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipConditionEventSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipConditionEventSymbol.fromJson(json);
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
