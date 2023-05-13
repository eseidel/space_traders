//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ShipRefine200ResponseDataProducedInner {
  /// Returns a new [ShipRefine200ResponseDataProducedInner] instance.
  ShipRefine200ResponseDataProducedInner({
    this.tradeSymbol,
    this.units,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tradeSymbol;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? units;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipRefine200ResponseDataProducedInner &&
          other.tradeSymbol == tradeSymbol &&
          other.units == units;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (tradeSymbol == null ? 0 : tradeSymbol!.hashCode) +
      (units == null ? 0 : units!.hashCode);

  @override
  String toString() =>
      'ShipRefine200ResponseDataProducedInner[tradeSymbol=$tradeSymbol, units=$units]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.tradeSymbol != null) {
      json[r'tradeSymbol'] = this.tradeSymbol;
    } else {
      json[r'tradeSymbol'] = null;
    }
    if (this.units != null) {
      json[r'units'] = this.units;
    } else {
      json[r'units'] = null;
    }
    return json;
  }

  /// Returns a new [ShipRefine200ResponseDataProducedInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipRefine200ResponseDataProducedInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipRefine200ResponseDataProducedInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipRefine200ResponseDataProducedInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipRefine200ResponseDataProducedInner(
        tradeSymbol: mapValueOfType<String>(json, r'tradeSymbol'),
        units: mapValueOfType<int>(json, r'units'),
      );
    }
    return null;
  }

  static List<ShipRefine200ResponseDataProducedInner>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipRefine200ResponseDataProducedInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipRefine200ResponseDataProducedInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipRefine200ResponseDataProducedInner> mapFromJson(
      dynamic json) {
    final map = <String, ShipRefine200ResponseDataProducedInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            ShipRefine200ResponseDataProducedInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipRefine200ResponseDataProducedInner-objects as value to a dart map
  static Map<String, List<ShipRefine200ResponseDataProducedInner>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipRefine200ResponseDataProducedInner>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipRefine200ResponseDataProducedInner.listFromJson(
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
  static const requiredKeys = <String>{};
}
