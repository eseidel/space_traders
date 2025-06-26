enum ShipConditionEventSymbolProp {
  reactorOverload._('REACTOR_OVERLOAD'),
  energySpikeFromMineral._('ENERGY_SPIKE_FROM_MINERAL'),
  solarFlareInterference._('SOLAR_FLARE_INTERFERENCE'),
  coolantLeak._('COOLANT_LEAK'),
  powerDistributionFluctuation._('POWER_DISTRIBUTION_FLUCTUATION'),
  magneticFieldDisruption._('MAGNETIC_FIELD_DISRUPTION'),
  hullMicrometeoriteStrikes._('HULL_MICROMETEORITE_STRIKES'),
  structuralStressFractures._('STRUCTURAL_STRESS_FRACTURES'),
  corrosiveMineralContamination._('CORROSIVE_MINERAL_CONTAMINATION'),
  thermalExpansionMismatch._('THERMAL_EXPANSION_MISMATCH'),
  vibrationDamageFromDrilling._('VIBRATION_DAMAGE_FROM_DRILLING'),
  electromagneticFieldInterference._('ELECTROMAGNETIC_FIELD_INTERFERENCE'),
  impactWithExtractedDebris._('IMPACT_WITH_EXTRACTED_DEBRIS'),
  fuelEfficiencyDegradation._('FUEL_EFFICIENCY_DEGRADATION'),
  coolantSystemAgeing._('COOLANT_SYSTEM_AGEING'),
  dustMicroabrasions._('DUST_MICROABRASIONS'),
  thrusterNozzleWear._('THRUSTER_NOZZLE_WEAR'),
  exhaustPortClogging._('EXHAUST_PORT_CLOGGING'),
  bearingLubricationFade._('BEARING_LUBRICATION_FADE'),
  sensorCalibrationDrift._('SENSOR_CALIBRATION_DRIFT'),
  hullMicrometeoriteDamage._('HULL_MICROMETEORITE_DAMAGE'),
  spaceDebrisCollision._('SPACE_DEBRIS_COLLISION'),
  thermalStress._('THERMAL_STRESS'),
  vibrationOverload._('VIBRATION_OVERLOAD'),
  pressureDifferentialStress._('PRESSURE_DIFFERENTIAL_STRESS'),
  electromagneticSurgeEffects._('ELECTROMAGNETIC_SURGE_EFFECTS'),
  atmosphericEntryHeat._('ATMOSPHERIC_ENTRY_HEAT');

  const ShipConditionEventSymbolProp._(this.value);

  factory ShipConditionEventSymbolProp.fromJson(String json) {
    return ShipConditionEventSymbolProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown ShipConditionEventSymbolProp value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipConditionEventSymbolProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipConditionEventSymbolProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
