//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The type of system.
class SystemType {
  /// Instantiate a new enum with the provided [value].
  const SystemType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const NEUTRON_STAR = SystemType._(r'NEUTRON_STAR');
  static const RED_STAR = SystemType._(r'RED_STAR');
  static const ORANGE_STAR = SystemType._(r'ORANGE_STAR');
  static const BLUE_STAR = SystemType._(r'BLUE_STAR');
  static const YOUNG_STAR = SystemType._(r'YOUNG_STAR');
  static const WHITE_DWARF = SystemType._(r'WHITE_DWARF');
  static const BLACK_HOLE = SystemType._(r'BLACK_HOLE');
  static const HYPERGIANT = SystemType._(r'HYPERGIANT');
  static const NEBULA = SystemType._(r'NEBULA');
  static const UNSTABLE = SystemType._(r'UNSTABLE');

  /// List of all possible values in this [enum][SystemType].
  static const values = <SystemType>[
    NEUTRON_STAR,
    RED_STAR,
    ORANGE_STAR,
    BLUE_STAR,
    YOUNG_STAR,
    WHITE_DWARF,
    BLACK_HOLE,
    HYPERGIANT,
    NEBULA,
    UNSTABLE,
  ];

  static SystemType? fromJson(dynamic value) =>
      SystemTypeTypeTransformer().decode(value);

  static List<SystemType> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SystemType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SystemType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SystemType] to String,
/// and [decode] dynamic data back to [SystemType].
class SystemTypeTypeTransformer {
  factory SystemTypeTypeTransformer() =>
      _instance ??= const SystemTypeTypeTransformer._();

  const SystemTypeTypeTransformer._();

  String encode(SystemType data) => data.value;

  /// Decodes a [dynamic value][data] to a SystemType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SystemType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'NEUTRON_STAR':
          return SystemType.NEUTRON_STAR;
        case r'RED_STAR':
          return SystemType.RED_STAR;
        case r'ORANGE_STAR':
          return SystemType.ORANGE_STAR;
        case r'BLUE_STAR':
          return SystemType.BLUE_STAR;
        case r'YOUNG_STAR':
          return SystemType.YOUNG_STAR;
        case r'WHITE_DWARF':
          return SystemType.WHITE_DWARF;
        case r'BLACK_HOLE':
          return SystemType.BLACK_HOLE;
        case r'HYPERGIANT':
          return SystemType.HYPERGIANT;
        case r'NEBULA':
          return SystemType.NEBULA;
        case r'UNSTABLE':
          return SystemType.UNSTABLE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SystemTypeTypeTransformer] instance.
  static SystemTypeTypeTransformer? _instance;
}
