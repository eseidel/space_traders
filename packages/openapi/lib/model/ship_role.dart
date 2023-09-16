//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The registered role of the ship
class ShipRole {
  /// Instantiate a new enum with the provided [value].
  const ShipRole._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const FABRICATOR = ShipRole._(r'FABRICATOR');
  static const HARVESTER = ShipRole._(r'HARVESTER');
  static const HAULER = ShipRole._(r'HAULER');
  static const INTERCEPTOR = ShipRole._(r'INTERCEPTOR');
  static const EXCAVATOR = ShipRole._(r'EXCAVATOR');
  static const TRANSPORT = ShipRole._(r'TRANSPORT');
  static const REPAIR = ShipRole._(r'REPAIR');
  static const SURVEYOR = ShipRole._(r'SURVEYOR');
  static const COMMAND = ShipRole._(r'COMMAND');
  static const CARRIER = ShipRole._(r'CARRIER');
  static const PATROL = ShipRole._(r'PATROL');
  static const SATELLITE = ShipRole._(r'SATELLITE');
  static const EXPLORER = ShipRole._(r'EXPLORER');
  static const REFINERY = ShipRole._(r'REFINERY');

  /// List of all possible values in this [enum][ShipRole].
  static const values = <ShipRole>[
    FABRICATOR,
    HARVESTER,
    HAULER,
    INTERCEPTOR,
    EXCAVATOR,
    TRANSPORT,
    REPAIR,
    SURVEYOR,
    COMMAND,
    CARRIER,
    PATROL,
    SATELLITE,
    EXPLORER,
    REFINERY,
  ];

  static ShipRole? fromJson(dynamic value) =>
      ShipRoleTypeTransformer().decode(value);

  static List<ShipRole> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipRole] to String,
/// and [decode] dynamic data back to [ShipRole].
class ShipRoleTypeTransformer {
  factory ShipRoleTypeTransformer() =>
      _instance ??= const ShipRoleTypeTransformer._();

  const ShipRoleTypeTransformer._();

  String encode(ShipRole data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipRole.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipRole? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'FABRICATOR':
          return ShipRole.FABRICATOR;
        case r'HARVESTER':
          return ShipRole.HARVESTER;
        case r'HAULER':
          return ShipRole.HAULER;
        case r'INTERCEPTOR':
          return ShipRole.INTERCEPTOR;
        case r'EXCAVATOR':
          return ShipRole.EXCAVATOR;
        case r'TRANSPORT':
          return ShipRole.TRANSPORT;
        case r'REPAIR':
          return ShipRole.REPAIR;
        case r'SURVEYOR':
          return ShipRole.SURVEYOR;
        case r'COMMAND':
          return ShipRole.COMMAND;
        case r'CARRIER':
          return ShipRole.CARRIER;
        case r'PATROL':
          return ShipRole.PATROL;
        case r'SATELLITE':
          return ShipRole.SATELLITE;
        case r'EXPLORER':
          return ShipRole.EXPLORER;
        case r'REFINERY':
          return ShipRole.REFINERY;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipRoleTypeTransformer] instance.
  static ShipRoleTypeTransformer? _instance;
}
