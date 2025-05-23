//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class TradeGood {
  /// Returns a new [TradeGood] instance.
  TradeGood({
    required this.symbol,
    required this.name,
    required this.description,
  });

  TradeSymbol symbol;

  /// The name of the good.
  String name;

  /// The description of the good.
  String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeGood &&
          other.symbol == symbol &&
          other.name == name &&
          other.description == description;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (name.hashCode) + (description.hashCode);

  @override
  String toString() =>
      'TradeGood[symbol=$symbol, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [TradeGood] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TradeGood? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "TradeGood[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "TradeGood[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TradeGood(
        symbol: TradeSymbol.fromJson(json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<TradeGood> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TradeGood>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TradeGood.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TradeGood> mapFromJson(dynamic json) {
    final map = <String, TradeGood>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TradeGood.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TradeGood-objects as value to a dart map
  static Map<String, List<TradeGood>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TradeGood>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TradeGood.listFromJson(
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
    'name',
    'description',
  };
}
