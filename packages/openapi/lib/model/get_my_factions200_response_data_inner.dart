//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetMyFactions200ResponseDataInner {
  /// Returns a new [GetMyFactions200ResponseDataInner] instance.
  GetMyFactions200ResponseDataInner({
    required this.symbol,
    required this.reputation,
  });

  String symbol;

  int reputation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetMyFactions200ResponseDataInner &&
          other.symbol == symbol &&
          other.reputation == reputation;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (reputation.hashCode);

  @override
  String toString() =>
      'GetMyFactions200ResponseDataInner[symbol=$symbol, reputation=$reputation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'reputation'] = this.reputation;
    return json;
  }

  /// Returns a new [GetMyFactions200ResponseDataInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetMyFactions200ResponseDataInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetMyFactions200ResponseDataInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetMyFactions200ResponseDataInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetMyFactions200ResponseDataInner(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        reputation: mapValueOfType<int>(json, r'reputation')!,
      );
    }
    return null;
  }

  static List<GetMyFactions200ResponseDataInner> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetMyFactions200ResponseDataInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetMyFactions200ResponseDataInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetMyFactions200ResponseDataInner> mapFromJson(
      dynamic json) {
    final map = <String, GetMyFactions200ResponseDataInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetMyFactions200ResponseDataInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetMyFactions200ResponseDataInner-objects as value to a dart map
  static Map<String, List<GetMyFactions200ResponseDataInner>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetMyFactions200ResponseDataInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetMyFactions200ResponseDataInner.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
    'reputation',
  };
}
