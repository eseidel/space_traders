//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ScannedShipMountsInner {
  /// Returns a new [ScannedShipMountsInner] instance.
  ScannedShipMountsInner({
    required this.symbol,
  });

  /// The symbol of the mount.
  String symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedShipMountsInner && other.symbol == symbol;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode);

  @override
  String toString() => 'ScannedShipMountsInner[symbol=$symbol]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    return json;
  }

  /// Returns a new [ScannedShipMountsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ScannedShipMountsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ScannedShipMountsInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ScannedShipMountsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ScannedShipMountsInner(
        symbol: mapValueOfType<String>(json, r'symbol')!,
      );
    }
    return null;
  }

  static List<ScannedShipMountsInner>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ScannedShipMountsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ScannedShipMountsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ScannedShipMountsInner> mapFromJson(dynamic json) {
    final map = <String, ScannedShipMountsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScannedShipMountsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ScannedShipMountsInner-objects as value to a dart map
  static Map<String, List<ScannedShipMountsInner>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ScannedShipMountsInner>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScannedShipMountsInner.listFromJson(
          entry.value,
          growable: growable,
        );
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
  };
}
