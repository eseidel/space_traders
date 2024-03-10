//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ExtractResources201ResponseDataEventsInner {
  /// Returns a new [ExtractResources201ResponseDataEventsInner] instance.
  ExtractResources201ResponseDataEventsInner({
    required this.symbol,
    required this.component,
    required this.name,
    required this.description,
  });

  ExtractResources201ResponseDataEventsInnerSymbolEnum symbol;

  ExtractResources201ResponseDataEventsInnerComponentEnum component;

  /// The name of the event.
  String name;

  /// A description of the event.
  String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractResources201ResponseDataEventsInner &&
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
      'ExtractResources201ResponseDataEventsInner[symbol=$symbol, component=$component, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'component'] = this.component;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [ExtractResources201ResponseDataEventsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExtractResources201ResponseDataEventsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ExtractResources201ResponseDataEventsInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ExtractResources201ResponseDataEventsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ExtractResources201ResponseDataEventsInner(
        symbol: ExtractResources201ResponseDataEventsInnerSymbolEnum.fromJson(
            json[r'symbol'])!,
        component:
            ExtractResources201ResponseDataEventsInnerComponentEnum.fromJson(
                json[r'component'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<ExtractResources201ResponseDataEventsInner> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExtractResources201ResponseDataEventsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExtractResources201ResponseDataEventsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExtractResources201ResponseDataEventsInner> mapFromJson(
      dynamic json) {
    final map = <String, ExtractResources201ResponseDataEventsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            ExtractResources201ResponseDataEventsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExtractResources201ResponseDataEventsInner-objects as value to a dart map
  static Map<String, List<ExtractResources201ResponseDataEventsInner>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExtractResources201ResponseDataEventsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] =
            ExtractResources201ResponseDataEventsInner.listFromJson(
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

class ExtractResources201ResponseDataEventsInnerSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const ExtractResources201ResponseDataEventsInnerSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const REACTOR_OVERLOAD =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'REACTOR_OVERLOAD');
  static const ENERGY_SPIKE_FROM_MINERAL =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'ENERGY_SPIKE_FROM_MINERAL');
  static const SOLAR_FLARE_INTERFERENCE =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'SOLAR_FLARE_INTERFERENCE');
  static const COOLANT_LEAK =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(r'COOLANT_LEAK');
  static const POWER_DISTRIBUTION_FLUCTUATION =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'POWER_DISTRIBUTION_FLUCTUATION');
  static const MAGNETIC_FIELD_DISRUPTION =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'MAGNETIC_FIELD_DISRUPTION');
  static const HULL_MICROMETEORITE_STRIKES =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'HULL_MICROMETEORITE_STRIKES');
  static const STRUCTURAL_STRESS_FRACTURES =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'STRUCTURAL_STRESS_FRACTURES');
  static const CORROSIVE_MINERAL_CONTAMINATION =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'CORROSIVE_MINERAL_CONTAMINATION');
  static const THERMAL_EXPANSION_MISMATCH =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'THERMAL_EXPANSION_MISMATCH');
  static const VIBRATION_DAMAGE_FROM_DRILLING =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'VIBRATION_DAMAGE_FROM_DRILLING');
  static const ELECTROMAGNETIC_FIELD_INTERFERENCE =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'ELECTROMAGNETIC_FIELD_INTERFERENCE');
  static const IMPACT_WITH_EXTRACTED_DEBRIS =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'IMPACT_WITH_EXTRACTED_DEBRIS');
  static const FUEL_EFFICIENCY_DEGRADATION =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'FUEL_EFFICIENCY_DEGRADATION');
  static const COOLANT_SYSTEM_AGEING =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'COOLANT_SYSTEM_AGEING');
  static const DUST_MICROABRASIONS =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'DUST_MICROABRASIONS');
  static const THRUSTER_NOZZLE_WEAR =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'THRUSTER_NOZZLE_WEAR');
  static const EXHAUST_PORT_CLOGGING =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'EXHAUST_PORT_CLOGGING');
  static const BEARING_LUBRICATION_FADE =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'BEARING_LUBRICATION_FADE');
  static const SENSOR_CALIBRATION_DRIFT =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'SENSOR_CALIBRATION_DRIFT');
  static const HULL_MICROMETEORITE_DAMAGE =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'HULL_MICROMETEORITE_DAMAGE');
  static const SPACE_DEBRIS_COLLISION =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'SPACE_DEBRIS_COLLISION');
  static const THERMAL_STRESS =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(r'THERMAL_STRESS');
  static const VIBRATION_OVERLOAD =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'VIBRATION_OVERLOAD');
  static const PRESSURE_DIFFERENTIAL_STRESS =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'PRESSURE_DIFFERENTIAL_STRESS');
  static const ELECTROMAGNETIC_SURGE_EFFECTS =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'ELECTROMAGNETIC_SURGE_EFFECTS');
  static const ATMOSPHERIC_ENTRY_HEAT =
      ExtractResources201ResponseDataEventsInnerSymbolEnum._(
          r'ATMOSPHERIC_ENTRY_HEAT');

  /// List of all possible values in this [enum][ExtractResources201ResponseDataEventsInnerSymbolEnum].
  static const values = <ExtractResources201ResponseDataEventsInnerSymbolEnum>[
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

  static ExtractResources201ResponseDataEventsInnerSymbolEnum? fromJson(
          dynamic value) =>
      ExtractResources201ResponseDataEventsInnerSymbolEnumTypeTransformer()
          .decode(value);

  static List<ExtractResources201ResponseDataEventsInnerSymbolEnum>
      listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExtractResources201ResponseDataEventsInnerSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value =
            ExtractResources201ResponseDataEventsInnerSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ExtractResources201ResponseDataEventsInnerSymbolEnum] to String,
/// and [decode] dynamic data back to [ExtractResources201ResponseDataEventsInnerSymbolEnum].
class ExtractResources201ResponseDataEventsInnerSymbolEnumTypeTransformer {
  factory ExtractResources201ResponseDataEventsInnerSymbolEnumTypeTransformer() =>
      _instance ??=
          const ExtractResources201ResponseDataEventsInnerSymbolEnumTypeTransformer
              ._();

  const ExtractResources201ResponseDataEventsInnerSymbolEnumTypeTransformer._();

  String encode(ExtractResources201ResponseDataEventsInnerSymbolEnum data) =>
      data.value;

  /// Decodes a [dynamic value][data] to a ExtractResources201ResponseDataEventsInnerSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ExtractResources201ResponseDataEventsInnerSymbolEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'REACTOR_OVERLOAD':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .REACTOR_OVERLOAD;
        case r'ENERGY_SPIKE_FROM_MINERAL':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .ENERGY_SPIKE_FROM_MINERAL;
        case r'SOLAR_FLARE_INTERFERENCE':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .SOLAR_FLARE_INTERFERENCE;
        case r'COOLANT_LEAK':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .COOLANT_LEAK;
        case r'POWER_DISTRIBUTION_FLUCTUATION':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .POWER_DISTRIBUTION_FLUCTUATION;
        case r'MAGNETIC_FIELD_DISRUPTION':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .MAGNETIC_FIELD_DISRUPTION;
        case r'HULL_MICROMETEORITE_STRIKES':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .HULL_MICROMETEORITE_STRIKES;
        case r'STRUCTURAL_STRESS_FRACTURES':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .STRUCTURAL_STRESS_FRACTURES;
        case r'CORROSIVE_MINERAL_CONTAMINATION':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .CORROSIVE_MINERAL_CONTAMINATION;
        case r'THERMAL_EXPANSION_MISMATCH':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .THERMAL_EXPANSION_MISMATCH;
        case r'VIBRATION_DAMAGE_FROM_DRILLING':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .VIBRATION_DAMAGE_FROM_DRILLING;
        case r'ELECTROMAGNETIC_FIELD_INTERFERENCE':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .ELECTROMAGNETIC_FIELD_INTERFERENCE;
        case r'IMPACT_WITH_EXTRACTED_DEBRIS':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .IMPACT_WITH_EXTRACTED_DEBRIS;
        case r'FUEL_EFFICIENCY_DEGRADATION':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .FUEL_EFFICIENCY_DEGRADATION;
        case r'COOLANT_SYSTEM_AGEING':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .COOLANT_SYSTEM_AGEING;
        case r'DUST_MICROABRASIONS':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .DUST_MICROABRASIONS;
        case r'THRUSTER_NOZZLE_WEAR':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .THRUSTER_NOZZLE_WEAR;
        case r'EXHAUST_PORT_CLOGGING':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .EXHAUST_PORT_CLOGGING;
        case r'BEARING_LUBRICATION_FADE':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .BEARING_LUBRICATION_FADE;
        case r'SENSOR_CALIBRATION_DRIFT':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .SENSOR_CALIBRATION_DRIFT;
        case r'HULL_MICROMETEORITE_DAMAGE':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .HULL_MICROMETEORITE_DAMAGE;
        case r'SPACE_DEBRIS_COLLISION':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .SPACE_DEBRIS_COLLISION;
        case r'THERMAL_STRESS':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .THERMAL_STRESS;
        case r'VIBRATION_OVERLOAD':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .VIBRATION_OVERLOAD;
        case r'PRESSURE_DIFFERENTIAL_STRESS':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .PRESSURE_DIFFERENTIAL_STRESS;
        case r'ELECTROMAGNETIC_SURGE_EFFECTS':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .ELECTROMAGNETIC_SURGE_EFFECTS;
        case r'ATMOSPHERIC_ENTRY_HEAT':
          return ExtractResources201ResponseDataEventsInnerSymbolEnum
              .ATMOSPHERIC_ENTRY_HEAT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ExtractResources201ResponseDataEventsInnerSymbolEnumTypeTransformer] instance.
  static ExtractResources201ResponseDataEventsInnerSymbolEnumTypeTransformer?
      _instance;
}

class ExtractResources201ResponseDataEventsInnerComponentEnum {
  /// Instantiate a new enum with the provided [value].
  const ExtractResources201ResponseDataEventsInnerComponentEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const FRAME =
      ExtractResources201ResponseDataEventsInnerComponentEnum._(r'FRAME');
  static const REACTOR =
      ExtractResources201ResponseDataEventsInnerComponentEnum._(r'REACTOR');
  static const ENGINE =
      ExtractResources201ResponseDataEventsInnerComponentEnum._(r'ENGINE');

  /// List of all possible values in this [enum][ExtractResources201ResponseDataEventsInnerComponentEnum].
  static const values =
      <ExtractResources201ResponseDataEventsInnerComponentEnum>[
    FRAME,
    REACTOR,
    ENGINE,
  ];

  static ExtractResources201ResponseDataEventsInnerComponentEnum? fromJson(
          dynamic value) =>
      ExtractResources201ResponseDataEventsInnerComponentEnumTypeTransformer()
          .decode(value);

  static List<ExtractResources201ResponseDataEventsInnerComponentEnum>
      listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExtractResources201ResponseDataEventsInnerComponentEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value =
            ExtractResources201ResponseDataEventsInnerComponentEnum.fromJson(
                row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ExtractResources201ResponseDataEventsInnerComponentEnum] to String,
/// and [decode] dynamic data back to [ExtractResources201ResponseDataEventsInnerComponentEnum].
class ExtractResources201ResponseDataEventsInnerComponentEnumTypeTransformer {
  factory ExtractResources201ResponseDataEventsInnerComponentEnumTypeTransformer() =>
      _instance ??=
          const ExtractResources201ResponseDataEventsInnerComponentEnumTypeTransformer
              ._();

  const ExtractResources201ResponseDataEventsInnerComponentEnumTypeTransformer._();

  String encode(ExtractResources201ResponseDataEventsInnerComponentEnum data) =>
      data.value;

  /// Decodes a [dynamic value][data] to a ExtractResources201ResponseDataEventsInnerComponentEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ExtractResources201ResponseDataEventsInnerComponentEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'FRAME':
          return ExtractResources201ResponseDataEventsInnerComponentEnum.FRAME;
        case r'REACTOR':
          return ExtractResources201ResponseDataEventsInnerComponentEnum
              .REACTOR;
        case r'ENGINE':
          return ExtractResources201ResponseDataEventsInnerComponentEnum.ENGINE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ExtractResources201ResponseDataEventsInnerComponentEnumTypeTransformer] instance.
  static ExtractResources201ResponseDataEventsInnerComponentEnumTypeTransformer?
      _instance;
}
