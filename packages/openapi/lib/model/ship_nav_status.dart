//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The current status of the ship
class ShipNavStatus {
  /// Instantiate a new enum with the provided [value].
  const ShipNavStatus._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const IN_TRANSIT = ShipNavStatus._(r'IN_TRANSIT');
  static const IN_ORBIT = ShipNavStatus._(r'IN_ORBIT');
  static const DOCKED = ShipNavStatus._(r'DOCKED');

  /// List of all possible values in this [enum][ShipNavStatus].
  static const values = <ShipNavStatus>[
    IN_TRANSIT,
    IN_ORBIT,
    DOCKED,
  ];

  static ShipNavStatus? fromJson(dynamic value) =>
      ShipNavStatusTypeTransformer().decode(value);

  static List<ShipNavStatus>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipNavStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipNavStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipNavStatus] to String,
/// and [decode] dynamic data back to [ShipNavStatus].
class ShipNavStatusTypeTransformer {
  factory ShipNavStatusTypeTransformer() =>
      _instance ??= const ShipNavStatusTypeTransformer._();

  const ShipNavStatusTypeTransformer._();

  String encode(ShipNavStatus data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipNavStatus.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipNavStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'IN_TRANSIT':
          return ShipNavStatus.IN_TRANSIT;
        case r'IN_ORBIT':
          return ShipNavStatus.IN_ORBIT;
        case r'DOCKED':
          return ShipNavStatus.DOCKED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipNavStatusTypeTransformer] instance.
  static ShipNavStatusTypeTransformer? _instance;
}
