//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The supply level of a trade good.
class SupplyLevel {
  /// Instantiate a new enum with the provided [value].
  const SupplyLevel._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SCARCE = SupplyLevel._(r'SCARCE');
  static const LIMITED = SupplyLevel._(r'LIMITED');
  static const MODERATE = SupplyLevel._(r'MODERATE');
  static const HIGH = SupplyLevel._(r'HIGH');
  static const ABUNDANT = SupplyLevel._(r'ABUNDANT');

  /// List of all possible values in this [enum][SupplyLevel].
  static const values = <SupplyLevel>[
    SCARCE,
    LIMITED,
    MODERATE,
    HIGH,
    ABUNDANT,
  ];

  static SupplyLevel? fromJson(dynamic value) =>
      SupplyLevelTypeTransformer().decode(value);

  static List<SupplyLevel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SupplyLevel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SupplyLevel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SupplyLevel] to String,
/// and [decode] dynamic data back to [SupplyLevel].
class SupplyLevelTypeTransformer {
  factory SupplyLevelTypeTransformer() =>
      _instance ??= const SupplyLevelTypeTransformer._();

  const SupplyLevelTypeTransformer._();

  String encode(SupplyLevel data) => data.value;

  /// Decodes a [dynamic value][data] to a SupplyLevel.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SupplyLevel? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SCARCE':
          return SupplyLevel.SCARCE;
        case r'LIMITED':
          return SupplyLevel.LIMITED;
        case r'MODERATE':
          return SupplyLevel.MODERATE;
        case r'HIGH':
          return SupplyLevel.HIGH;
        case r'ABUNDANT':
          return SupplyLevel.ABUNDANT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SupplyLevelTypeTransformer] instance.
  static SupplyLevelTypeTransformer? _instance;
}
