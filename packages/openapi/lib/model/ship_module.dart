//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipModule {
  /// Returns a new [ShipModule] instance.
  ShipModule({
    required this.symbol,
    this.capacity,
    this.range,
    required this.name,
    required this.description,
    required this.requirements,
  });

  /// The symbol of the module.
  ShipModuleSymbolEnum symbol;

  /// Modules that provide capacity, such as cargo hold or crew quarters will show this value to denote how much of a bonus the module grants.
  ///
  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? capacity;

  /// Modules that have a range will such as a sensor array show this value to denote how far can the module reach with its capabilities.
  ///
  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? range;

  /// Name of this module.
  String name;

  /// Description of this module.
  String description;

  ShipRequirements requirements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipModule &&
          other.symbol == symbol &&
          other.capacity == capacity &&
          other.range == range &&
          other.name == name &&
          other.description == description &&
          other.requirements == requirements;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (capacity == null ? 0 : capacity!.hashCode) +
      (range == null ? 0 : range!.hashCode) +
      (name.hashCode) +
      (description.hashCode) +
      (requirements.hashCode);

  @override
  String toString() =>
      'ShipModule[symbol=$symbol, capacity=$capacity, range=$range, name=$name, description=$description, requirements=$requirements]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    if (this.capacity != null) {
      json[r'capacity'] = this.capacity;
    } else {
      json[r'capacity'] = null;
    }
    if (this.range != null) {
      json[r'range'] = this.range;
    } else {
      json[r'range'] = null;
    }
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    json[r'requirements'] = this.requirements;
    return json;
  }

  /// Returns a new [ShipModule] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipModule? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipModule[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipModule[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipModule(
        symbol: ShipModuleSymbolEnum.fromJson(json[r'symbol'])!,
        capacity: mapValueOfType<int>(json, r'capacity'),
        range: mapValueOfType<int>(json, r'range'),
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        requirements: ShipRequirements.fromJson(json[r'requirements'])!,
      );
    }
    return null;
  }

  static List<ShipModule> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipModule>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipModule.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipModule> mapFromJson(dynamic json) {
    final map = <String, ShipModule>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipModule.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipModule-objects as value to a dart map
  static Map<String, List<ShipModule>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipModule>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipModule.listFromJson(
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
    'name',
    'description',
    'requirements',
  };
}

/// The symbol of the module.
class ShipModuleSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipModuleSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const MINERAL_PROCESSOR_I =
      ShipModuleSymbolEnum._(r'MODULE_MINERAL_PROCESSOR_I');
  static const GAS_PROCESSOR_I =
      ShipModuleSymbolEnum._(r'MODULE_GAS_PROCESSOR_I');
  static const CARGO_HOLD_I = ShipModuleSymbolEnum._(r'MODULE_CARGO_HOLD_I');
  static const CARGO_HOLD_II = ShipModuleSymbolEnum._(r'MODULE_CARGO_HOLD_II');
  static const CARGO_HOLD_III =
      ShipModuleSymbolEnum._(r'MODULE_CARGO_HOLD_III');
  static const CREW_QUARTERS_I =
      ShipModuleSymbolEnum._(r'MODULE_CREW_QUARTERS_I');
  static const ENVOY_QUARTERS_I =
      ShipModuleSymbolEnum._(r'MODULE_ENVOY_QUARTERS_I');
  static const PASSENGER_CABIN_I =
      ShipModuleSymbolEnum._(r'MODULE_PASSENGER_CABIN_I');
  static const MICRO_REFINERY_I =
      ShipModuleSymbolEnum._(r'MODULE_MICRO_REFINERY_I');
  static const ORE_REFINERY_I =
      ShipModuleSymbolEnum._(r'MODULE_ORE_REFINERY_I');
  static const FUEL_REFINERY_I =
      ShipModuleSymbolEnum._(r'MODULE_FUEL_REFINERY_I');
  static const SCIENCE_LAB_I = ShipModuleSymbolEnum._(r'MODULE_SCIENCE_LAB_I');
  static const JUMP_DRIVE_I = ShipModuleSymbolEnum._(r'MODULE_JUMP_DRIVE_I');
  static const JUMP_DRIVE_II = ShipModuleSymbolEnum._(r'MODULE_JUMP_DRIVE_II');
  static const JUMP_DRIVE_III =
      ShipModuleSymbolEnum._(r'MODULE_JUMP_DRIVE_III');
  static const WARP_DRIVE_I = ShipModuleSymbolEnum._(r'MODULE_WARP_DRIVE_I');
  static const WARP_DRIVE_II = ShipModuleSymbolEnum._(r'MODULE_WARP_DRIVE_II');
  static const WARP_DRIVE_III =
      ShipModuleSymbolEnum._(r'MODULE_WARP_DRIVE_III');
  static const SHIELD_GENERATOR_I =
      ShipModuleSymbolEnum._(r'MODULE_SHIELD_GENERATOR_I');
  static const SHIELD_GENERATOR_II =
      ShipModuleSymbolEnum._(r'MODULE_SHIELD_GENERATOR_II');

  /// List of all possible values in this [enum][ShipModuleSymbolEnum].
  static const values = <ShipModuleSymbolEnum>[
    MINERAL_PROCESSOR_I,
    GAS_PROCESSOR_I,
    CARGO_HOLD_I,
    CARGO_HOLD_II,
    CARGO_HOLD_III,
    CREW_QUARTERS_I,
    ENVOY_QUARTERS_I,
    PASSENGER_CABIN_I,
    MICRO_REFINERY_I,
    ORE_REFINERY_I,
    FUEL_REFINERY_I,
    SCIENCE_LAB_I,
    JUMP_DRIVE_I,
    JUMP_DRIVE_II,
    JUMP_DRIVE_III,
    WARP_DRIVE_I,
    WARP_DRIVE_II,
    WARP_DRIVE_III,
    SHIELD_GENERATOR_I,
    SHIELD_GENERATOR_II,
  ];

  static ShipModuleSymbolEnum? fromJson(dynamic value) =>
      ShipModuleSymbolEnumTypeTransformer().decode(value);

  static List<ShipModuleSymbolEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipModuleSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipModuleSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipModuleSymbolEnum] to String,
/// and [decode] dynamic data back to [ShipModuleSymbolEnum].
class ShipModuleSymbolEnumTypeTransformer {
  factory ShipModuleSymbolEnumTypeTransformer() =>
      _instance ??= const ShipModuleSymbolEnumTypeTransformer._();

  const ShipModuleSymbolEnumTypeTransformer._();

  String encode(ShipModuleSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipModuleSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipModuleSymbolEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'MODULE_MINERAL_PROCESSOR_I':
          return ShipModuleSymbolEnum.MINERAL_PROCESSOR_I;
        case r'MODULE_GAS_PROCESSOR_I':
          return ShipModuleSymbolEnum.GAS_PROCESSOR_I;
        case r'MODULE_CARGO_HOLD_I':
          return ShipModuleSymbolEnum.CARGO_HOLD_I;
        case r'MODULE_CARGO_HOLD_II':
          return ShipModuleSymbolEnum.CARGO_HOLD_II;
        case r'MODULE_CARGO_HOLD_III':
          return ShipModuleSymbolEnum.CARGO_HOLD_III;
        case r'MODULE_CREW_QUARTERS_I':
          return ShipModuleSymbolEnum.CREW_QUARTERS_I;
        case r'MODULE_ENVOY_QUARTERS_I':
          return ShipModuleSymbolEnum.ENVOY_QUARTERS_I;
        case r'MODULE_PASSENGER_CABIN_I':
          return ShipModuleSymbolEnum.PASSENGER_CABIN_I;
        case r'MODULE_MICRO_REFINERY_I':
          return ShipModuleSymbolEnum.MICRO_REFINERY_I;
        case r'MODULE_ORE_REFINERY_I':
          return ShipModuleSymbolEnum.ORE_REFINERY_I;
        case r'MODULE_FUEL_REFINERY_I':
          return ShipModuleSymbolEnum.FUEL_REFINERY_I;
        case r'MODULE_SCIENCE_LAB_I':
          return ShipModuleSymbolEnum.SCIENCE_LAB_I;
        case r'MODULE_JUMP_DRIVE_I':
          return ShipModuleSymbolEnum.JUMP_DRIVE_I;
        case r'MODULE_JUMP_DRIVE_II':
          return ShipModuleSymbolEnum.JUMP_DRIVE_II;
        case r'MODULE_JUMP_DRIVE_III':
          return ShipModuleSymbolEnum.JUMP_DRIVE_III;
        case r'MODULE_WARP_DRIVE_I':
          return ShipModuleSymbolEnum.WARP_DRIVE_I;
        case r'MODULE_WARP_DRIVE_II':
          return ShipModuleSymbolEnum.WARP_DRIVE_II;
        case r'MODULE_WARP_DRIVE_III':
          return ShipModuleSymbolEnum.WARP_DRIVE_III;
        case r'MODULE_SHIELD_GENERATOR_I':
          return ShipModuleSymbolEnum.SHIELD_GENERATOR_I;
        case r'MODULE_SHIELD_GENERATOR_II':
          return ShipModuleSymbolEnum.SHIELD_GENERATOR_II;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipModuleSymbolEnumTypeTransformer] instance.
  static ShipModuleSymbolEnumTypeTransformer? _instance;
}
