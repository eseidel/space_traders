//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The unique identifier of the modifier.
class WaypointModifierSymbol {
  /// Instantiate a new enum with the provided [value].
  const WaypointModifierSymbol._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const STRIPPED = WaypointModifierSymbol._(r'STRIPPED');
  static const UNSTABLE = WaypointModifierSymbol._(r'UNSTABLE');
  static const RADIATION_LEAK = WaypointModifierSymbol._(r'RADIATION_LEAK');
  static const CRITICAL_LIMIT = WaypointModifierSymbol._(r'CRITICAL_LIMIT');
  static const CIVIL_UNREST = WaypointModifierSymbol._(r'CIVIL_UNREST');

  /// List of all possible values in this [enum][WaypointModifierSymbol].
  static const values = <WaypointModifierSymbol>[
    STRIPPED,
    UNSTABLE,
    RADIATION_LEAK,
    CRITICAL_LIMIT,
    CIVIL_UNREST,
  ];

  static WaypointModifierSymbol? fromJson(dynamic value) =>
      WaypointModifierSymbolTypeTransformer().decode(value);

  static List<WaypointModifierSymbol> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WaypointModifierSymbol>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WaypointModifierSymbol.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WaypointModifierSymbol] to String,
/// and [decode] dynamic data back to [WaypointModifierSymbol].
class WaypointModifierSymbolTypeTransformer {
  factory WaypointModifierSymbolTypeTransformer() =>
      _instance ??= const WaypointModifierSymbolTypeTransformer._();

  const WaypointModifierSymbolTypeTransformer._();

  String encode(WaypointModifierSymbol data) => data.value;

  /// Decodes a [dynamic value][data] to a WaypointModifierSymbol.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WaypointModifierSymbol? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'STRIPPED':
          return WaypointModifierSymbol.STRIPPED;
        case r'UNSTABLE':
          return WaypointModifierSymbol.UNSTABLE;
        case r'RADIATION_LEAK':
          return WaypointModifierSymbol.RADIATION_LEAK;
        case r'CRITICAL_LIMIT':
          return WaypointModifierSymbol.CRITICAL_LIMIT;
        case r'CIVIL_UNREST':
          return WaypointModifierSymbol.CIVIL_UNREST;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WaypointModifierSymbolTypeTransformer] instance.
  static WaypointModifierSymbolTypeTransformer? _instance;
}
