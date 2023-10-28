//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ConstructionMaterial {
  /// Returns a new [ConstructionMaterial] instance.
  ConstructionMaterial({
    required this.tradeSymbol,
    required this.required_,
    required this.fulfilled,
  });

  TradeSymbol tradeSymbol;

  /// The number of units required.
  int required_;

  /// The number of units fulfilled toward the required amount.
  int fulfilled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstructionMaterial &&
          other.tradeSymbol == tradeSymbol &&
          other.required_ == required_ &&
          other.fulfilled == fulfilled;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (tradeSymbol.hashCode) + (required_.hashCode) + (fulfilled.hashCode);

  @override
  String toString() =>
      'ConstructionMaterial[tradeSymbol=$tradeSymbol, required_=$required_, fulfilled=$fulfilled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'tradeSymbol'] = this.tradeSymbol;
    json[r'required'] = this.required_;
    json[r'fulfilled'] = this.fulfilled;
    return json;
  }

  /// Returns a new [ConstructionMaterial] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConstructionMaterial? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ConstructionMaterial[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ConstructionMaterial[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConstructionMaterial(
        tradeSymbol: TradeSymbol.fromJson(json[r'tradeSymbol'])!,
        required_: mapValueOfType<int>(json, r'required')!,
        fulfilled: mapValueOfType<int>(json, r'fulfilled')!,
      );
    }
    return null;
  }

  static List<ConstructionMaterial> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ConstructionMaterial>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConstructionMaterial.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConstructionMaterial> mapFromJson(dynamic json) {
    final map = <String, ConstructionMaterial>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConstructionMaterial.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConstructionMaterial-objects as value to a dart map
  static Map<String, List<ConstructionMaterial>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ConstructionMaterial>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ConstructionMaterial.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'tradeSymbol',
    'required',
    'fulfilled',
  };
}
