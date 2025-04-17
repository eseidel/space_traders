//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The ship's set speed when traveling between waypoints or systems.
class ShipNavFlightMode {
  /// Instantiate a new enum with the provided [value].
  const ShipNavFlightMode._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const DRIFT = ShipNavFlightMode._(r'DRIFT');
  static const STEALTH = ShipNavFlightMode._(r'STEALTH');
  static const CRUISE = ShipNavFlightMode._(r'CRUISE');
  static const BURN = ShipNavFlightMode._(r'BURN');

  /// List of all possible values in this [enum][ShipNavFlightMode].
  static const values = <ShipNavFlightMode>[
    DRIFT,
    STEALTH,
    CRUISE,
    BURN,
  ];

  static ShipNavFlightMode? fromJson(dynamic value) =>
      ShipNavFlightModeTypeTransformer().decode(value);

  static List<ShipNavFlightMode> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipNavFlightMode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipNavFlightMode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipNavFlightMode] to String,
/// and [decode] dynamic data back to [ShipNavFlightMode].
class ShipNavFlightModeTypeTransformer {
  factory ShipNavFlightModeTypeTransformer() =>
      _instance ??= const ShipNavFlightModeTypeTransformer._();

  const ShipNavFlightModeTypeTransformer._();

  String encode(ShipNavFlightMode data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipNavFlightMode.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipNavFlightMode? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'DRIFT':
          return ShipNavFlightMode.DRIFT;
        case r'STEALTH':
          return ShipNavFlightMode.STEALTH;
        case r'CRUISE':
          return ShipNavFlightMode.CRUISE;
        case r'BURN':
          return ShipNavFlightMode.BURN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipNavFlightModeTypeTransformer] instance.
  static ShipNavFlightModeTypeTransformer? _instance;
}
