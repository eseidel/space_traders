//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The size of the deposit. This value indicates how much can be extracted from the survey before it is exhausted.
class SurveySize {
  /// Instantiate a new enum with the provided [value].
  const SurveySize._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SMALL = SurveySize._(r'SMALL');
  static const MODERATE = SurveySize._(r'MODERATE');
  static const LARGE = SurveySize._(r'LARGE');

  /// List of all possible values in this [enum][SurveySize].
  static const values = <SurveySize>[
    SMALL,
    MODERATE,
    LARGE,
  ];

  static SurveySize? fromJson(dynamic value) =>
      SurveySizeTypeTransformer().decode(value);

  static List<SurveySize> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SurveySize>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SurveySize.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SurveySize] to String,
/// and [decode] dynamic data back to [SurveySize].
class SurveySizeTypeTransformer {
  factory SurveySizeTypeTransformer() =>
      _instance ??= const SurveySizeTypeTransformer._();

  const SurveySizeTypeTransformer._();

  String encode(SurveySize data) => data.value;

  /// Decodes a [dynamic value][data] to a SurveySize.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SurveySize? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SMALL':
          return SurveySize.SMALL;
        case r'MODERATE':
          return SurveySize.MODERATE;
        case r'LARGE':
          return SurveySize.LARGE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SurveySizeTypeTransformer] instance.
  static SurveySizeTypeTransformer? _instance;
}
