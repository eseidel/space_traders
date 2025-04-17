//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class WaypointModifier {
  /// Returns a new [WaypointModifier] instance.
  WaypointModifier({
    required this.symbol,
    required this.name,
    required this.description,
  });

  WaypointModifierSymbol symbol;

  /// The name of the trait.
  String name;

  /// A description of the trait.
  String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaypointModifier &&
          other.symbol == symbol &&
          other.name == name &&
          other.description == description;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (name.hashCode) + (description.hashCode);

  @override
  String toString() =>
      'WaypointModifier[symbol=$symbol, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [WaypointModifier] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WaypointModifier? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "WaypointModifier[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "WaypointModifier[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WaypointModifier(
        symbol: WaypointModifierSymbol.fromJson(json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<WaypointModifier> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WaypointModifier>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WaypointModifier.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WaypointModifier> mapFromJson(dynamic json) {
    final map = <String, WaypointModifier>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WaypointModifier.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WaypointModifier-objects as value to a dart map
  static Map<String, List<WaypointModifier>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<WaypointModifier>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WaypointModifier.listFromJson(
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
