//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipMount {
  /// Returns a new [ShipMount] instance.
  ShipMount({
    required this.symbol,
    required this.name,
    this.description,
    this.strength,
    this.deposits = const [],
    required this.requirements,
  });

  /// Symbo of this mount.
  ShipMountSymbolEnum symbol;

  /// Name of this mount.
  String name;

  /// Description of this mount.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  /// Mounts that have this value, such as mining lasers, denote how powerful this mount's capabilities are.
  ///
  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? strength;

  /// Mounts that have this value denote what goods can be produced from using the mount.
  List<ShipMountDepositsEnum> deposits;

  ShipRequirements requirements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipMount &&
          other.symbol == symbol &&
          other.name == name &&
          other.description == description &&
          other.strength == strength &&
          other.deposits == deposits &&
          other.requirements == requirements;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (name.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (strength == null ? 0 : strength!.hashCode) +
      (deposits.hashCode) +
      (requirements.hashCode);

  @override
  String toString() =>
      'ShipMount[symbol=$symbol, name=$name, description=$description, strength=$strength, deposits=$deposits, requirements=$requirements]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'name'] = this.name;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.strength != null) {
      json[r'strength'] = this.strength;
    } else {
      json[r'strength'] = null;
    }
    json[r'deposits'] = this.deposits;
    json[r'requirements'] = this.requirements;
    return json;
  }

  /// Returns a new [ShipMount] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipMount? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipMount[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipMount[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipMount(
        symbol: ShipMountSymbolEnum.fromJson(json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description'),
        strength: mapValueOfType<int>(json, r'strength'),
        deposits: ShipMountDepositsEnum.listFromJson(json[r'deposits']),
        requirements: ShipRequirements.fromJson(json[r'requirements'])!,
      );
    }
    return null;
  }

  static List<ShipMount> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipMount>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipMount.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipMount> mapFromJson(dynamic json) {
    final map = <String, ShipMount>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipMount.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipMount-objects as value to a dart map
  static Map<String, List<ShipMount>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipMount>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipMount.listFromJson(
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
    'requirements',
  };
}

/// Symbo of this mount.
class ShipMountSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipMountSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const GAS_SIPHON_I = ShipMountSymbolEnum._(r'MOUNT_GAS_SIPHON_I');
  static const GAS_SIPHON_II = ShipMountSymbolEnum._(r'MOUNT_GAS_SIPHON_II');
  static const GAS_SIPHON_III = ShipMountSymbolEnum._(r'MOUNT_GAS_SIPHON_III');
  static const SURVEYOR_I = ShipMountSymbolEnum._(r'MOUNT_SURVEYOR_I');
  static const SURVEYOR_II = ShipMountSymbolEnum._(r'MOUNT_SURVEYOR_II');
  static const SURVEYOR_III = ShipMountSymbolEnum._(r'MOUNT_SURVEYOR_III');
  static const SENSOR_ARRAY_I = ShipMountSymbolEnum._(r'MOUNT_SENSOR_ARRAY_I');
  static const SENSOR_ARRAY_II =
      ShipMountSymbolEnum._(r'MOUNT_SENSOR_ARRAY_II');
  static const SENSOR_ARRAY_III =
      ShipMountSymbolEnum._(r'MOUNT_SENSOR_ARRAY_III');
  static const MINING_LASER_I = ShipMountSymbolEnum._(r'MOUNT_MINING_LASER_I');
  static const MINING_LASER_II =
      ShipMountSymbolEnum._(r'MOUNT_MINING_LASER_II');
  static const MINING_LASER_III =
      ShipMountSymbolEnum._(r'MOUNT_MINING_LASER_III');
  static const LASER_CANNON_I = ShipMountSymbolEnum._(r'MOUNT_LASER_CANNON_I');
  static const MISSILE_LAUNCHER_I =
      ShipMountSymbolEnum._(r'MOUNT_MISSILE_LAUNCHER_I');
  static const TURRET_I = ShipMountSymbolEnum._(r'MOUNT_TURRET_I');

  /// List of all possible values in this [enum][ShipMountSymbolEnum].
  static const values = <ShipMountSymbolEnum>[
    GAS_SIPHON_I,
    GAS_SIPHON_II,
    GAS_SIPHON_III,
    SURVEYOR_I,
    SURVEYOR_II,
    SURVEYOR_III,
    SENSOR_ARRAY_I,
    SENSOR_ARRAY_II,
    SENSOR_ARRAY_III,
    MINING_LASER_I,
    MINING_LASER_II,
    MINING_LASER_III,
    LASER_CANNON_I,
    MISSILE_LAUNCHER_I,
    TURRET_I,
  ];

  static ShipMountSymbolEnum? fromJson(dynamic value) =>
      ShipMountSymbolEnumTypeTransformer().decode(value);

  static List<ShipMountSymbolEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipMountSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipMountSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipMountSymbolEnum] to String,
/// and [decode] dynamic data back to [ShipMountSymbolEnum].
class ShipMountSymbolEnumTypeTransformer {
  factory ShipMountSymbolEnumTypeTransformer() =>
      _instance ??= const ShipMountSymbolEnumTypeTransformer._();

  const ShipMountSymbolEnumTypeTransformer._();

  String encode(ShipMountSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipMountSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipMountSymbolEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'MOUNT_GAS_SIPHON_I':
          return ShipMountSymbolEnum.GAS_SIPHON_I;
        case r'MOUNT_GAS_SIPHON_II':
          return ShipMountSymbolEnum.GAS_SIPHON_II;
        case r'MOUNT_GAS_SIPHON_III':
          return ShipMountSymbolEnum.GAS_SIPHON_III;
        case r'MOUNT_SURVEYOR_I':
          return ShipMountSymbolEnum.SURVEYOR_I;
        case r'MOUNT_SURVEYOR_II':
          return ShipMountSymbolEnum.SURVEYOR_II;
        case r'MOUNT_SURVEYOR_III':
          return ShipMountSymbolEnum.SURVEYOR_III;
        case r'MOUNT_SENSOR_ARRAY_I':
          return ShipMountSymbolEnum.SENSOR_ARRAY_I;
        case r'MOUNT_SENSOR_ARRAY_II':
          return ShipMountSymbolEnum.SENSOR_ARRAY_II;
        case r'MOUNT_SENSOR_ARRAY_III':
          return ShipMountSymbolEnum.SENSOR_ARRAY_III;
        case r'MOUNT_MINING_LASER_I':
          return ShipMountSymbolEnum.MINING_LASER_I;
        case r'MOUNT_MINING_LASER_II':
          return ShipMountSymbolEnum.MINING_LASER_II;
        case r'MOUNT_MINING_LASER_III':
          return ShipMountSymbolEnum.MINING_LASER_III;
        case r'MOUNT_LASER_CANNON_I':
          return ShipMountSymbolEnum.LASER_CANNON_I;
        case r'MOUNT_MISSILE_LAUNCHER_I':
          return ShipMountSymbolEnum.MISSILE_LAUNCHER_I;
        case r'MOUNT_TURRET_I':
          return ShipMountSymbolEnum.TURRET_I;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipMountSymbolEnumTypeTransformer] instance.
  static ShipMountSymbolEnumTypeTransformer? _instance;
}

class ShipMountDepositsEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipMountDepositsEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const QUARTZ_SAND = ShipMountDepositsEnum._(r'QUARTZ_SAND');
  static const SILICON_CRYSTALS = ShipMountDepositsEnum._(r'SILICON_CRYSTALS');
  static const PRECIOUS_STONES = ShipMountDepositsEnum._(r'PRECIOUS_STONES');
  static const ICE_WATER = ShipMountDepositsEnum._(r'ICE_WATER');
  static const AMMONIA_ICE = ShipMountDepositsEnum._(r'AMMONIA_ICE');
  static const IRON_ORE = ShipMountDepositsEnum._(r'IRON_ORE');
  static const COPPER_ORE = ShipMountDepositsEnum._(r'COPPER_ORE');
  static const SILVER_ORE = ShipMountDepositsEnum._(r'SILVER_ORE');
  static const ALUMINUM_ORE = ShipMountDepositsEnum._(r'ALUMINUM_ORE');
  static const GOLD_ORE = ShipMountDepositsEnum._(r'GOLD_ORE');
  static const PLATINUM_ORE = ShipMountDepositsEnum._(r'PLATINUM_ORE');
  static const DIAMONDS = ShipMountDepositsEnum._(r'DIAMONDS');
  static const URANITE_ORE = ShipMountDepositsEnum._(r'URANITE_ORE');
  static const MERITIUM_ORE = ShipMountDepositsEnum._(r'MERITIUM_ORE');

  /// List of all possible values in this [enum][ShipMountDepositsEnum].
  static const values = <ShipMountDepositsEnum>[
    QUARTZ_SAND,
    SILICON_CRYSTALS,
    PRECIOUS_STONES,
    ICE_WATER,
    AMMONIA_ICE,
    IRON_ORE,
    COPPER_ORE,
    SILVER_ORE,
    ALUMINUM_ORE,
    GOLD_ORE,
    PLATINUM_ORE,
    DIAMONDS,
    URANITE_ORE,
    MERITIUM_ORE,
  ];

  static ShipMountDepositsEnum? fromJson(dynamic value) =>
      ShipMountDepositsEnumTypeTransformer().decode(value);

  static List<ShipMountDepositsEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipMountDepositsEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipMountDepositsEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipMountDepositsEnum] to String,
/// and [decode] dynamic data back to [ShipMountDepositsEnum].
class ShipMountDepositsEnumTypeTransformer {
  factory ShipMountDepositsEnumTypeTransformer() =>
      _instance ??= const ShipMountDepositsEnumTypeTransformer._();

  const ShipMountDepositsEnumTypeTransformer._();

  String encode(ShipMountDepositsEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipMountDepositsEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipMountDepositsEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'QUARTZ_SAND':
          return ShipMountDepositsEnum.QUARTZ_SAND;
        case r'SILICON_CRYSTALS':
          return ShipMountDepositsEnum.SILICON_CRYSTALS;
        case r'PRECIOUS_STONES':
          return ShipMountDepositsEnum.PRECIOUS_STONES;
        case r'ICE_WATER':
          return ShipMountDepositsEnum.ICE_WATER;
        case r'AMMONIA_ICE':
          return ShipMountDepositsEnum.AMMONIA_ICE;
        case r'IRON_ORE':
          return ShipMountDepositsEnum.IRON_ORE;
        case r'COPPER_ORE':
          return ShipMountDepositsEnum.COPPER_ORE;
        case r'SILVER_ORE':
          return ShipMountDepositsEnum.SILVER_ORE;
        case r'ALUMINUM_ORE':
          return ShipMountDepositsEnum.ALUMINUM_ORE;
        case r'GOLD_ORE':
          return ShipMountDepositsEnum.GOLD_ORE;
        case r'PLATINUM_ORE':
          return ShipMountDepositsEnum.PLATINUM_ORE;
        case r'DIAMONDS':
          return ShipMountDepositsEnum.DIAMONDS;
        case r'URANITE_ORE':
          return ShipMountDepositsEnum.URANITE_ORE;
        case r'MERITIUM_ORE':
          return ShipMountDepositsEnum.MERITIUM_ORE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipMountDepositsEnumTypeTransformer] instance.
  static ShipMountDepositsEnumTypeTransformer? _instance;
}
