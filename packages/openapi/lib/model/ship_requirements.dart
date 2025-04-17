//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipRequirements {
  /// Returns a new [ShipRequirements] instance.
  ShipRequirements({
    this.power,
    this.crew,
    this.slots,
  });

  /// The amount of power required from the reactor.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? power;

  /// The number of crew required for operation.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? crew;

  /// The number of module slots required for installation.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? slots;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipRequirements &&
          other.power == power &&
          other.crew == crew &&
          other.slots == slots;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (power == null ? 0 : power!.hashCode) +
      (crew == null ? 0 : crew!.hashCode) +
      (slots == null ? 0 : slots!.hashCode);

  @override
  String toString() =>
      'ShipRequirements[power=$power, crew=$crew, slots=$slots]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.power != null) {
      json[r'power'] = this.power;
    } else {
      json[r'power'] = null;
    }
    if (this.crew != null) {
      json[r'crew'] = this.crew;
    } else {
      json[r'crew'] = null;
    }
    if (this.slots != null) {
      json[r'slots'] = this.slots;
    } else {
      json[r'slots'] = null;
    }
    return json;
  }

  /// Returns a new [ShipRequirements] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipRequirements? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipRequirements[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipRequirements[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipRequirements(
        power: mapValueOfType<int>(json, r'power'),
        crew: mapValueOfType<int>(json, r'crew'),
        slots: mapValueOfType<int>(json, r'slots'),
      );
    }
    return null;
  }

  static List<ShipRequirements> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipRequirements>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipRequirements.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipRequirements> mapFromJson(dynamic json) {
    final map = <String, ShipRequirements>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipRequirements.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipRequirements-objects as value to a dart map
  static Map<String, List<ShipRequirements>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipRequirements>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipRequirements.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
