//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Survey {
  /// Returns a new [Survey] instance.
  Survey({
    required this.signature,
    required this.symbol,
    this.deposits = const [],
    required this.expiration,
    required this.size,
  });

  /// A unique signature for the location of this survey. This signature is verified when attempting an extraction using this survey.
  String signature;

  /// The symbol of the waypoint that this survey is for.
  String symbol;

  /// A list of deposits that can be found at this location. A ship will extract one of these deposits when using this survey in an extraction request. If multiple deposits of the same type are present, the chance of extracting that deposit is increased.
  List<SurveyDeposit> deposits;

  /// The date and time when the survey expires. After this date and time, the survey will no longer be available for extraction.
  DateTime expiration;

  /// The size of the deposit. This value indicates how much can be extracted from the survey before it is exhausted.
  SurveySizeEnum size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Survey &&
          other.signature == signature &&
          other.symbol == symbol &&
          _deepEquality.equals(other.deposits, deposits) &&
          other.expiration == expiration &&
          other.size == size;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (signature.hashCode) +
      (symbol.hashCode) +
      (deposits.hashCode) +
      (expiration.hashCode) +
      (size.hashCode);

  @override
  String toString() =>
      'Survey[signature=$signature, symbol=$symbol, deposits=$deposits, expiration=$expiration, size=$size]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'signature'] = this.signature;
    json[r'symbol'] = this.symbol;
    json[r'deposits'] = this.deposits;
    json[r'expiration'] = this.expiration.toUtc().toIso8601String();
    json[r'size'] = this.size;
    return json;
  }

  /// Returns a new [Survey] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Survey? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Survey[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Survey[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Survey(
        signature: mapValueOfType<String>(json, r'signature')!,
        symbol: mapValueOfType<String>(json, r'symbol')!,
        deposits: SurveyDeposit.listFromJson(json[r'deposits']),
        expiration: mapDateTime(json, r'expiration', r'')!,
        size: SurveySizeEnum.fromJson(json[r'size'])!,
      );
    }
    return null;
  }

  static List<Survey> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Survey>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Survey.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Survey> mapFromJson(dynamic json) {
    final map = <String, Survey>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Survey.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Survey-objects as value to a dart map
  static Map<String, List<Survey>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Survey>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Survey.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'signature',
    'symbol',
    'deposits',
    'expiration',
    'size',
  };
}

/// The size of the deposit. This value indicates how much can be extracted from the survey before it is exhausted.
class SurveySizeEnum {
  /// Instantiate a new enum with the provided [value].
  const SurveySizeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SMALL = SurveySizeEnum._(r'SMALL');
  static const MODERATE = SurveySizeEnum._(r'MODERATE');
  static const LARGE = SurveySizeEnum._(r'LARGE');

  /// List of all possible values in this [enum][SurveySizeEnum].
  static const values = <SurveySizeEnum>[
    SMALL,
    MODERATE,
    LARGE,
  ];

  static SurveySizeEnum? fromJson(dynamic value) =>
      SurveySizeEnumTypeTransformer().decode(value);

  static List<SurveySizeEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SurveySizeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SurveySizeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SurveySizeEnum] to String,
/// and [decode] dynamic data back to [SurveySizeEnum].
class SurveySizeEnumTypeTransformer {
  factory SurveySizeEnumTypeTransformer() =>
      _instance ??= const SurveySizeEnumTypeTransformer._();

  const SurveySizeEnumTypeTransformer._();

  String encode(SurveySizeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SurveySizeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SurveySizeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SMALL':
          return SurveySizeEnum.SMALL;
        case r'MODERATE':
          return SurveySizeEnum.MODERATE;
        case r'LARGE':
          return SurveySizeEnum.LARGE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SurveySizeEnumTypeTransformer] instance.
  static SurveySizeEnumTypeTransformer? _instance;
}
