//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The type of waypoint.
class WaypointType {
  /// Instantiate a new enum with the provided [value].
  const WaypointType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PLANET = WaypointType._(r'PLANET');
  static const GAS_GIANT = WaypointType._(r'GAS_GIANT');
  static const MOON = WaypointType._(r'MOON');
  static const ORBITAL_STATION = WaypointType._(r'ORBITAL_STATION');
  static const JUMP_GATE = WaypointType._(r'JUMP_GATE');
  static const ASTEROID_FIELD = WaypointType._(r'ASTEROID_FIELD');
  static const ASTEROID = WaypointType._(r'ASTEROID');
  static const ENGINEERED_ASTEROID = WaypointType._(r'ENGINEERED_ASTEROID');
  static const ASTEROID_BASE = WaypointType._(r'ASTEROID_BASE');
  static const NEBULA = WaypointType._(r'NEBULA');
  static const DEBRIS_FIELD = WaypointType._(r'DEBRIS_FIELD');
  static const GRAVITY_WELL = WaypointType._(r'GRAVITY_WELL');
  static const ARTIFICIAL_GRAVITY_WELL =
      WaypointType._(r'ARTIFICIAL_GRAVITY_WELL');
  static const FUEL_STATION = WaypointType._(r'FUEL_STATION');

  /// List of all possible values in this [enum][WaypointType].
  static const values = <WaypointType>[
    PLANET,
    GAS_GIANT,
    MOON,
    ORBITAL_STATION,
    JUMP_GATE,
    ASTEROID_FIELD,
    ASTEROID,
    ENGINEERED_ASTEROID,
    ASTEROID_BASE,
    NEBULA,
    DEBRIS_FIELD,
    GRAVITY_WELL,
    ARTIFICIAL_GRAVITY_WELL,
    FUEL_STATION,
  ];

  static WaypointType? fromJson(dynamic value) =>
      WaypointTypeTypeTransformer().decode(value);

  static List<WaypointType> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WaypointType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WaypointType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WaypointType] to String,
/// and [decode] dynamic data back to [WaypointType].
class WaypointTypeTypeTransformer {
  factory WaypointTypeTypeTransformer() =>
      _instance ??= const WaypointTypeTypeTransformer._();

  const WaypointTypeTypeTransformer._();

  String encode(WaypointType data) => data.value;

  /// Decodes a [dynamic value][data] to a WaypointType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WaypointType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PLANET':
          return WaypointType.PLANET;
        case r'GAS_GIANT':
          return WaypointType.GAS_GIANT;
        case r'MOON':
          return WaypointType.MOON;
        case r'ORBITAL_STATION':
          return WaypointType.ORBITAL_STATION;
        case r'JUMP_GATE':
          return WaypointType.JUMP_GATE;
        case r'ASTEROID_FIELD':
          return WaypointType.ASTEROID_FIELD;
        case r'ASTEROID':
          return WaypointType.ASTEROID;
        case r'ENGINEERED_ASTEROID':
          return WaypointType.ENGINEERED_ASTEROID;
        case r'ASTEROID_BASE':
          return WaypointType.ASTEROID_BASE;
        case r'NEBULA':
          return WaypointType.NEBULA;
        case r'DEBRIS_FIELD':
          return WaypointType.DEBRIS_FIELD;
        case r'GRAVITY_WELL':
          return WaypointType.GRAVITY_WELL;
        case r'ARTIFICIAL_GRAVITY_WELL':
          return WaypointType.ARTIFICIAL_GRAVITY_WELL;
        case r'FUEL_STATION':
          return WaypointType.FUEL_STATION;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WaypointTypeTypeTransformer] instance.
  static WaypointTypeTypeTransformer? _instance;
}
