//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

/// Type of ship
class ShipType {
  /// Instantiate a new enum with the provided [value].
  const ShipType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PROBE = ShipType._(r'SHIP_PROBE');
  static const MINING_DRONE = ShipType._(r'SHIP_MINING_DRONE');
  static const INTERCEPTOR = ShipType._(r'SHIP_INTERCEPTOR');
  static const LIGHT_HAULER = ShipType._(r'SHIP_LIGHT_HAULER');
  static const COMMAND_FRIGATE = ShipType._(r'SHIP_COMMAND_FRIGATE');
  static const EXPLORER = ShipType._(r'SHIP_EXPLORER');
  static const HEAVY_FREIGHTER = ShipType._(r'SHIP_HEAVY_FREIGHTER');
  static const LIGHT_SHUTTLE = ShipType._(r'SHIP_LIGHT_SHUTTLE');
  static const ORE_HOUND = ShipType._(r'SHIP_ORE_HOUND');
  static const REFINING_FREIGHTER = ShipType._(r'SHIP_REFINING_FREIGHTER');

  /// List of all possible values in this [enum][ShipType].
  static const values = <ShipType>[
    PROBE,
    MINING_DRONE,
    INTERCEPTOR,
    LIGHT_HAULER,
    COMMAND_FRIGATE,
    EXPLORER,
    HEAVY_FREIGHTER,
    LIGHT_SHUTTLE,
    ORE_HOUND,
    REFINING_FREIGHTER,
  ];

  static ShipType? fromJson(dynamic value) =>
      ShipTypeTypeTransformer().decode(value);

  static List<ShipType>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipType] to String,
/// and [decode] dynamic data back to [ShipType].
class ShipTypeTypeTransformer {
  factory ShipTypeTypeTransformer() =>
      _instance ??= const ShipTypeTypeTransformer._();

  const ShipTypeTypeTransformer._();

  String encode(ShipType data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SHIP_PROBE':
          return ShipType.PROBE;
        case r'SHIP_MINING_DRONE':
          return ShipType.MINING_DRONE;
        case r'SHIP_INTERCEPTOR':
          return ShipType.INTERCEPTOR;
        case r'SHIP_LIGHT_HAULER':
          return ShipType.LIGHT_HAULER;
        case r'SHIP_COMMAND_FRIGATE':
          return ShipType.COMMAND_FRIGATE;
        case r'SHIP_EXPLORER':
          return ShipType.EXPLORER;
        case r'SHIP_HEAVY_FREIGHTER':
          return ShipType.HEAVY_FREIGHTER;
        case r'SHIP_LIGHT_SHUTTLE':
          return ShipType.LIGHT_SHUTTLE;
        case r'SHIP_ORE_HOUND':
          return ShipType.ORE_HOUND;
        case r'SHIP_REFINING_FREIGHTER':
          return ShipType.REFINING_FREIGHTER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipTypeTypeTransformer] instance.
  static ShipTypeTypeTransformer? _instance;
}
