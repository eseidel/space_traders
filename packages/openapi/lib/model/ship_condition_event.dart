//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipConditionEvent {
  /// Returns a new [ShipConditionEvent] instance.
  ShipConditionEvent({
    required this.symbol,
    required this.component,
    required this.name,
    required this.description,
  });

  ShipConditionEventSymbolEnum symbol;

  ShipConditionEventComponentEnum component;

  /// The name of the event.
  String name;

  /// A description of the event.
  String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipConditionEvent &&
          other.symbol == symbol &&
          other.component == component &&
          other.name == name &&
          other.description == description;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (component.hashCode) +
      (name.hashCode) +
      (description.hashCode);

  @override
  String toString() =>
      'ShipConditionEvent[symbol=$symbol, component=$component, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'component'] = this.component;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [ShipConditionEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipConditionEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipConditionEvent[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipConditionEvent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipConditionEvent(
        symbol: ShipConditionEventSymbolEnum.fromJson(json[r'symbol'])!,
        component:
            ShipConditionEventComponentEnum.fromJson(json[r'component'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<ShipConditionEvent> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipConditionEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipConditionEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipConditionEvent> mapFromJson(dynamic json) {
    final map = <String, ShipConditionEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipConditionEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipConditionEvent-objects as value to a dart map
  static Map<String, List<ShipConditionEvent>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipConditionEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipConditionEvent.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
    'component',
    'name',
    'description',
  };
}

class ShipConditionEventSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipConditionEventSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const REACTOR_OVERLOAD =
      ShipConditionEventSymbolEnum._(r'REACTOR_OVERLOAD');
  static const ENERGY_SPIKE_FROM_MINERAL =
      ShipConditionEventSymbolEnum._(r'ENERGY_SPIKE_FROM_MINERAL');
  static const SOLAR_FLARE_INTERFERENCE =
      ShipConditionEventSymbolEnum._(r'SOLAR_FLARE_INTERFERENCE');
  static const COOLANT_LEAK = ShipConditionEventSymbolEnum._(r'COOLANT_LEAK');
  static const POWER_DISTRIBUTION_FLUCTUATION =
      ShipConditionEventSymbolEnum._(r'POWER_DISTRIBUTION_FLUCTUATION');
  static const MAGNETIC_FIELD_DISRUPTION =
      ShipConditionEventSymbolEnum._(r'MAGNETIC_FIELD_DISRUPTION');
  static const HULL_MICROMETEORITE_STRIKES =
      ShipConditionEventSymbolEnum._(r'HULL_MICROMETEORITE_STRIKES');
  static const STRUCTURAL_STRESS_FRACTURES =
      ShipConditionEventSymbolEnum._(r'STRUCTURAL_STRESS_FRACTURES');
  static const CORROSIVE_MINERAL_CONTAMINATION =
      ShipConditionEventSymbolEnum._(r'CORROSIVE_MINERAL_CONTAMINATION');
  static const THERMAL_EXPANSION_MISMATCH =
      ShipConditionEventSymbolEnum._(r'THERMAL_EXPANSION_MISMATCH');
  static const VIBRATION_DAMAGE_FROM_DRILLING =
      ShipConditionEventSymbolEnum._(r'VIBRATION_DAMAGE_FROM_DRILLING');
  static const ELECTROMAGNETIC_FIELD_INTERFERENCE =
      ShipConditionEventSymbolEnum._(r'ELECTROMAGNETIC_FIELD_INTERFERENCE');
  static const IMPACT_WITH_EXTRACTED_DEBRIS =
      ShipConditionEventSymbolEnum._(r'IMPACT_WITH_EXTRACTED_DEBRIS');
  static const FUEL_EFFICIENCY_DEGRADATION =
      ShipConditionEventSymbolEnum._(r'FUEL_EFFICIENCY_DEGRADATION');
  static const COOLANT_SYSTEM_AGEING =
      ShipConditionEventSymbolEnum._(r'COOLANT_SYSTEM_AGEING');
  static const DUST_MICROABRASIONS =
      ShipConditionEventSymbolEnum._(r'DUST_MICROABRASIONS');
  static const THRUSTER_NOZZLE_WEAR =
      ShipConditionEventSymbolEnum._(r'THRUSTER_NOZZLE_WEAR');
  static const EXHAUST_PORT_CLOGGING =
      ShipConditionEventSymbolEnum._(r'EXHAUST_PORT_CLOGGING');
  static const BEARING_LUBRICATION_FADE =
      ShipConditionEventSymbolEnum._(r'BEARING_LUBRICATION_FADE');
  static const SENSOR_CALIBRATION_DRIFT =
      ShipConditionEventSymbolEnum._(r'SENSOR_CALIBRATION_DRIFT');
  static const HULL_MICROMETEORITE_DAMAGE =
      ShipConditionEventSymbolEnum._(r'HULL_MICROMETEORITE_DAMAGE');
  static const SPACE_DEBRIS_COLLISION =
      ShipConditionEventSymbolEnum._(r'SPACE_DEBRIS_COLLISION');
  static const THERMAL_STRESS =
      ShipConditionEventSymbolEnum._(r'THERMAL_STRESS');
  static const VIBRATION_OVERLOAD =
      ShipConditionEventSymbolEnum._(r'VIBRATION_OVERLOAD');
  static const PRESSURE_DIFFERENTIAL_STRESS =
      ShipConditionEventSymbolEnum._(r'PRESSURE_DIFFERENTIAL_STRESS');
  static const ELECTROMAGNETIC_SURGE_EFFECTS =
      ShipConditionEventSymbolEnum._(r'ELECTROMAGNETIC_SURGE_EFFECTS');
  static const ATMOSPHERIC_ENTRY_HEAT =
      ShipConditionEventSymbolEnum._(r'ATMOSPHERIC_ENTRY_HEAT');

  /// List of all possible values in this [enum][ShipConditionEventSymbolEnum].
  static const values = <ShipConditionEventSymbolEnum>[
    REACTOR_OVERLOAD,
    ENERGY_SPIKE_FROM_MINERAL,
    SOLAR_FLARE_INTERFERENCE,
    COOLANT_LEAK,
    POWER_DISTRIBUTION_FLUCTUATION,
    MAGNETIC_FIELD_DISRUPTION,
    HULL_MICROMETEORITE_STRIKES,
    STRUCTURAL_STRESS_FRACTURES,
    CORROSIVE_MINERAL_CONTAMINATION,
    THERMAL_EXPANSION_MISMATCH,
    VIBRATION_DAMAGE_FROM_DRILLING,
    ELECTROMAGNETIC_FIELD_INTERFERENCE,
    IMPACT_WITH_EXTRACTED_DEBRIS,
    FUEL_EFFICIENCY_DEGRADATION,
    COOLANT_SYSTEM_AGEING,
    DUST_MICROABRASIONS,
    THRUSTER_NOZZLE_WEAR,
    EXHAUST_PORT_CLOGGING,
    BEARING_LUBRICATION_FADE,
    SENSOR_CALIBRATION_DRIFT,
    HULL_MICROMETEORITE_DAMAGE,
    SPACE_DEBRIS_COLLISION,
    THERMAL_STRESS,
    VIBRATION_OVERLOAD,
    PRESSURE_DIFFERENTIAL_STRESS,
    ELECTROMAGNETIC_SURGE_EFFECTS,
    ATMOSPHERIC_ENTRY_HEAT,
  ];

  static ShipConditionEventSymbolEnum? fromJson(dynamic value) =>
      ShipConditionEventSymbolEnumTypeTransformer().decode(value);

  static List<ShipConditionEventSymbolEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipConditionEventSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipConditionEventSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipConditionEventSymbolEnum] to String,
/// and [decode] dynamic data back to [ShipConditionEventSymbolEnum].
class ShipConditionEventSymbolEnumTypeTransformer {
  factory ShipConditionEventSymbolEnumTypeTransformer() =>
      _instance ??= const ShipConditionEventSymbolEnumTypeTransformer._();

  const ShipConditionEventSymbolEnumTypeTransformer._();

  String encode(ShipConditionEventSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipConditionEventSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipConditionEventSymbolEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'REACTOR_OVERLOAD':
          return ShipConditionEventSymbolEnum.REACTOR_OVERLOAD;
        case r'ENERGY_SPIKE_FROM_MINERAL':
          return ShipConditionEventSymbolEnum.ENERGY_SPIKE_FROM_MINERAL;
        case r'SOLAR_FLARE_INTERFERENCE':
          return ShipConditionEventSymbolEnum.SOLAR_FLARE_INTERFERENCE;
        case r'COOLANT_LEAK':
          return ShipConditionEventSymbolEnum.COOLANT_LEAK;
        case r'POWER_DISTRIBUTION_FLUCTUATION':
          return ShipConditionEventSymbolEnum.POWER_DISTRIBUTION_FLUCTUATION;
        case r'MAGNETIC_FIELD_DISRUPTION':
          return ShipConditionEventSymbolEnum.MAGNETIC_FIELD_DISRUPTION;
        case r'HULL_MICROMETEORITE_STRIKES':
          return ShipConditionEventSymbolEnum.HULL_MICROMETEORITE_STRIKES;
        case r'STRUCTURAL_STRESS_FRACTURES':
          return ShipConditionEventSymbolEnum.STRUCTURAL_STRESS_FRACTURES;
        case r'CORROSIVE_MINERAL_CONTAMINATION':
          return ShipConditionEventSymbolEnum.CORROSIVE_MINERAL_CONTAMINATION;
        case r'THERMAL_EXPANSION_MISMATCH':
          return ShipConditionEventSymbolEnum.THERMAL_EXPANSION_MISMATCH;
        case r'VIBRATION_DAMAGE_FROM_DRILLING':
          return ShipConditionEventSymbolEnum.VIBRATION_DAMAGE_FROM_DRILLING;
        case r'ELECTROMAGNETIC_FIELD_INTERFERENCE':
          return ShipConditionEventSymbolEnum
              .ELECTROMAGNETIC_FIELD_INTERFERENCE;
        case r'IMPACT_WITH_EXTRACTED_DEBRIS':
          return ShipConditionEventSymbolEnum.IMPACT_WITH_EXTRACTED_DEBRIS;
        case r'FUEL_EFFICIENCY_DEGRADATION':
          return ShipConditionEventSymbolEnum.FUEL_EFFICIENCY_DEGRADATION;
        case r'COOLANT_SYSTEM_AGEING':
          return ShipConditionEventSymbolEnum.COOLANT_SYSTEM_AGEING;
        case r'DUST_MICROABRASIONS':
          return ShipConditionEventSymbolEnum.DUST_MICROABRASIONS;
        case r'THRUSTER_NOZZLE_WEAR':
          return ShipConditionEventSymbolEnum.THRUSTER_NOZZLE_WEAR;
        case r'EXHAUST_PORT_CLOGGING':
          return ShipConditionEventSymbolEnum.EXHAUST_PORT_CLOGGING;
        case r'BEARING_LUBRICATION_FADE':
          return ShipConditionEventSymbolEnum.BEARING_LUBRICATION_FADE;
        case r'SENSOR_CALIBRATION_DRIFT':
          return ShipConditionEventSymbolEnum.SENSOR_CALIBRATION_DRIFT;
        case r'HULL_MICROMETEORITE_DAMAGE':
          return ShipConditionEventSymbolEnum.HULL_MICROMETEORITE_DAMAGE;
        case r'SPACE_DEBRIS_COLLISION':
          return ShipConditionEventSymbolEnum.SPACE_DEBRIS_COLLISION;
        case r'THERMAL_STRESS':
          return ShipConditionEventSymbolEnum.THERMAL_STRESS;
        case r'VIBRATION_OVERLOAD':
          return ShipConditionEventSymbolEnum.VIBRATION_OVERLOAD;
        case r'PRESSURE_DIFFERENTIAL_STRESS':
          return ShipConditionEventSymbolEnum.PRESSURE_DIFFERENTIAL_STRESS;
        case r'ELECTROMAGNETIC_SURGE_EFFECTS':
          return ShipConditionEventSymbolEnum.ELECTROMAGNETIC_SURGE_EFFECTS;
        case r'ATMOSPHERIC_ENTRY_HEAT':
          return ShipConditionEventSymbolEnum.ATMOSPHERIC_ENTRY_HEAT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipConditionEventSymbolEnumTypeTransformer] instance.
  static ShipConditionEventSymbolEnumTypeTransformer? _instance;
}

class ShipConditionEventComponentEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipConditionEventComponentEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const FRAME = ShipConditionEventComponentEnum._(r'FRAME');
  static const REACTOR = ShipConditionEventComponentEnum._(r'REACTOR');
  static const ENGINE = ShipConditionEventComponentEnum._(r'ENGINE');

  /// List of all possible values in this [enum][ShipConditionEventComponentEnum].
  static const values = <ShipConditionEventComponentEnum>[
    FRAME,
    REACTOR,
    ENGINE,
  ];

  static ShipConditionEventComponentEnum? fromJson(dynamic value) =>
      ShipConditionEventComponentEnumTypeTransformer().decode(value);

  static List<ShipConditionEventComponentEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipConditionEventComponentEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipConditionEventComponentEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipConditionEventComponentEnum] to String,
/// and [decode] dynamic data back to [ShipConditionEventComponentEnum].
class ShipConditionEventComponentEnumTypeTransformer {
  factory ShipConditionEventComponentEnumTypeTransformer() =>
      _instance ??= const ShipConditionEventComponentEnumTypeTransformer._();

  const ShipConditionEventComponentEnumTypeTransformer._();

  String encode(ShipConditionEventComponentEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipConditionEventComponentEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipConditionEventComponentEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'FRAME':
          return ShipConditionEventComponentEnum.FRAME;
        case r'REACTOR':
          return ShipConditionEventComponentEnum.REACTOR;
        case r'ENGINE':
          return ShipConditionEventComponentEnum.ENGINE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipConditionEventComponentEnumTypeTransformer] instance.
  static ShipConditionEventComponentEnumTypeTransformer? _instance;
}
