//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipRefine201ResponseData {
  /// Returns a new [ShipRefine201ResponseData] instance.
  ShipRefine201ResponseData({
    required this.cargo,
    required this.cooldown,
    this.produced = const [],
    this.consumed = const [],
  });

  ShipCargo cargo;

  Cooldown cooldown;

  /// Goods that were produced by this refining process.
  List<ShipRefine201ResponseDataProducedInner> produced;

  /// Goods that were consumed during this refining process.
  List<ShipRefine201ResponseDataProducedInner> consumed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipRefine201ResponseData &&
          other.cargo == cargo &&
          other.cooldown == cooldown &&
          _deepEquality.equals(other.produced, produced) &&
          _deepEquality.equals(other.consumed, consumed);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cargo.hashCode) +
      (cooldown.hashCode) +
      (produced.hashCode) +
      (consumed.hashCode);

  @override
  String toString() =>
      'ShipRefine201ResponseData[cargo=$cargo, cooldown=$cooldown, produced=$produced, consumed=$consumed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cargo'] = this.cargo;
    json[r'cooldown'] = this.cooldown;
    json[r'produced'] = this.produced;
    json[r'consumed'] = this.consumed;
    return json;
  }

  /// Returns a new [ShipRefine201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipRefine201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipRefine201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipRefine201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipRefine201ResponseData(
        cargo: ShipCargo.fromJson(json[r'cargo'])!,
        cooldown: Cooldown.fromJson(json[r'cooldown'])!,
        produced: ShipRefine201ResponseDataProducedInner.listFromJson(
            json[r'produced']),
        consumed: ShipRefine201ResponseDataProducedInner.listFromJson(
            json[r'consumed']),
      );
    }
    return null;
  }

  static List<ShipRefine201ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipRefine201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipRefine201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipRefine201ResponseData> mapFromJson(dynamic json) {
    final map = <String, ShipRefine201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipRefine201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipRefine201ResponseData-objects as value to a dart map
  static Map<String, List<ShipRefine201ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipRefine201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipRefine201ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
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
