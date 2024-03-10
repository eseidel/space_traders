//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class RepairShip200ResponseData {
  /// Returns a new [RepairShip200ResponseData] instance.
  RepairShip200ResponseData({
    required this.agent,
    required this.ship,
    required this.transaction,
  });

  Agent agent;

  Ship ship;

  RepairTransaction transaction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairShip200ResponseData &&
          other.agent == agent &&
          other.ship == ship &&
          other.transaction == transaction;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (agent.hashCode) + (ship.hashCode) + (transaction.hashCode);

  @override
  String toString() =>
      'RepairShip200ResponseData[agent=$agent, ship=$ship, transaction=$transaction]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'agent'] = this.agent;
    json[r'ship'] = this.ship;
    json[r'transaction'] = this.transaction;
    return json;
  }

  /// Returns a new [RepairShip200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RepairShip200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "RepairShip200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "RepairShip200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RepairShip200ResponseData(
        agent: Agent.fromJson(json[r'agent'])!,
        ship: Ship.fromJson(json[r'ship'])!,
        transaction: RepairTransaction.fromJson(json[r'transaction'])!,
      );
    }
    return null;
  }

  static List<RepairShip200ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RepairShip200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RepairShip200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RepairShip200ResponseData> mapFromJson(dynamic json) {
    final map = <String, RepairShip200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RepairShip200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RepairShip200ResponseData-objects as value to a dart map
  static Map<String, List<RepairShip200ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RepairShip200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RepairShip200ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'agent',
    'ship',
    'transaction',
  };
}
