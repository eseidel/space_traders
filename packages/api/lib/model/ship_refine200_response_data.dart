//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ShipRefine200ResponseData {
  /// Returns a new [ShipRefine200ResponseData] instance.
  ShipRefine200ResponseData({
    required this.cargo,
    required this.cooldown,
    this.produced = const [],
    this.consumed = const [],
  });

  ShipCargo cargo;

  Cooldown cooldown;

  List<ShipRefine200ResponseDataProducedInner> produced;

  List<ShipRefine200ResponseDataProducedInner> consumed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipRefine200ResponseData &&
          other.cargo == cargo &&
          other.cooldown == cooldown &&
          other.produced == produced &&
          other.consumed == consumed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cargo.hashCode) +
      (cooldown.hashCode) +
      (produced.hashCode) +
      (consumed.hashCode);

  @override
  String toString() =>
      'ShipRefine200ResponseData[cargo=$cargo, cooldown=$cooldown, produced=$produced, consumed=$consumed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cargo'] = this.cargo;
    json[r'cooldown'] = this.cooldown;
    json[r'produced'] = this.produced;
    json[r'consumed'] = this.consumed;
    return json;
  }

  /// Returns a new [ShipRefine200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipRefine200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipRefine200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipRefine200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipRefine200ResponseData(
        cargo: ShipCargo.fromJson(json[r'cargo'])!,
        cooldown: Cooldown.fromJson(json[r'cooldown'])!,
        produced: ShipRefine200ResponseDataProducedInner.listFromJson(
            json[r'produced'])!,
        consumed: ShipRefine200ResponseDataProducedInner.listFromJson(
            json[r'consumed'])!,
      );
    }
    return null;
  }

  static List<ShipRefine200ResponseData>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipRefine200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipRefine200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipRefine200ResponseData> mapFromJson(dynamic json) {
    final map = <String, ShipRefine200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipRefine200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipRefine200ResponseData-objects as value to a dart map
  static Map<String, List<ShipRefine200ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipRefine200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipRefine200ResponseData.listFromJson(
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
    'cargo',
    'cooldown',
    'produced',
    'consumed',
  };
}
