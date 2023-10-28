//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Siphon {
  /// Returns a new [Siphon] instance.
  Siphon({
    required this.shipSymbol,
    required this.yield_,
  });

  /// Symbol of the ship that executed the siphon.
  String shipSymbol;

  SiphonYield yield_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Siphon &&
          other.shipSymbol == shipSymbol &&
          other.yield_ == yield_;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (shipSymbol.hashCode) + (yield_.hashCode);

  @override
  String toString() => 'Siphon[shipSymbol=$shipSymbol, yield_=$yield_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'yield'] = this.yield_;
    return json;
  }

  /// Returns a new [Siphon] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Siphon? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Siphon[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Siphon[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Siphon(
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        yield_: SiphonYield.fromJson(json[r'yield'])!,
      );
    }
    return null;
  }

  static List<Siphon> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Siphon>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Siphon.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Siphon> mapFromJson(dynamic json) {
    final map = <String, Siphon>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Siphon.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Siphon-objects as value to a dart map
  static Map<String, List<Siphon>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Siphon>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Siphon.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'shipSymbol',
    'yield',
  };
}
