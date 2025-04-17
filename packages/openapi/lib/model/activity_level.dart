//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The activity level of a trade good. If the good is an import, this represents how strong consumption is. If the good is an export, this represents how strong the production is for the good. When activity is strong, consumption or production is near maximum capacity. When activity is weak, consumption or production is near minimum capacity.
class ActivityLevel {
  /// Instantiate a new enum with the provided [value].
  const ActivityLevel._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const WEAK = ActivityLevel._(r'WEAK');
  static const GROWING = ActivityLevel._(r'GROWING');
  static const STRONG = ActivityLevel._(r'STRONG');
  static const RESTRICTED = ActivityLevel._(r'RESTRICTED');

  /// List of all possible values in this [enum][ActivityLevel].
  static const values = <ActivityLevel>[
    WEAK,
    GROWING,
    STRONG,
    RESTRICTED,
  ];

  static ActivityLevel? fromJson(dynamic value) =>
      ActivityLevelTypeTransformer().decode(value);

  static List<ActivityLevel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ActivityLevel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ActivityLevel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ActivityLevel] to String,
/// and [decode] dynamic data back to [ActivityLevel].
class ActivityLevelTypeTransformer {
  factory ActivityLevelTypeTransformer() =>
      _instance ??= const ActivityLevelTypeTransformer._();

  const ActivityLevelTypeTransformer._();

  String encode(ActivityLevel data) => data.value;

  /// Decodes a [dynamic value][data] to a ActivityLevel.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ActivityLevel? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'WEAK':
          return ActivityLevel.WEAK;
        case r'GROWING':
          return ActivityLevel.GROWING;
        case r'STRONG':
          return ActivityLevel.STRONG;
        case r'RESTRICTED':
          return ActivityLevel.RESTRICTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ActivityLevelTypeTransformer] instance.
  static ActivityLevelTypeTransformer? _instance;
}
