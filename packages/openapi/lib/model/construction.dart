//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Construction {
  /// Returns a new [Construction] instance.
  Construction({
    required this.symbol,
    this.materials = const [],
    required this.isComplete,
  });

  /// The symbol of the waypoint.
  String symbol;

  /// The materials required to construct the waypoint.
  List<ConstructionMaterial> materials;

  /// Whether the waypoint has been constructed.
  bool isComplete;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Construction &&
          other.symbol == symbol &&
          other.materials == materials &&
          other.isComplete == isComplete;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (materials.hashCode) + (isComplete.hashCode);

  @override
  String toString() =>
      'Construction[symbol=$symbol, materials=$materials, isComplete=$isComplete]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'materials'] = this.materials;
    json[r'isComplete'] = this.isComplete;
    return json;
  }

  /// Returns a new [Construction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Construction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Construction[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Construction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Construction(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        materials: ConstructionMaterial.listFromJson(json[r'materials']),
        isComplete: mapValueOfType<bool>(json, r'isComplete')!,
      );
    }
    return null;
  }

  static List<Construction> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Construction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Construction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Construction> mapFromJson(dynamic json) {
    final map = <String, Construction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Construction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Construction-objects as value to a dart map
  static Map<String, List<Construction>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Construction>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Construction.listFromJson(
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
    'materials',
    'isComplete',
  };
}
