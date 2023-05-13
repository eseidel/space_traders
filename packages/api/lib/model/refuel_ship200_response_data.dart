//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class RefuelShip200ResponseData {
  /// Returns a new [RefuelShip200ResponseData] instance.
  RefuelShip200ResponseData({
    required this.agent,
    required this.fuel,
  });

  Agent agent;

  ShipFuel fuel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RefuelShip200ResponseData &&
     other.agent == agent &&
     other.fuel == fuel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (agent.hashCode) +
    (fuel.hashCode);

  @override
  String toString() => 'RefuelShip200ResponseData[agent=$agent, fuel=$fuel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'agent'] = this.agent;
      json[r'fuel'] = this.fuel;
    return json;
  }

  /// Returns a new [RefuelShip200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RefuelShip200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RefuelShip200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RefuelShip200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RefuelShip200ResponseData(
        agent: Agent.fromJson(json[r'agent'])!,
        fuel: ShipFuel.fromJson(json[r'fuel'])!,
      );
    }
    return null;
  }

  static List<RefuelShip200ResponseData>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RefuelShip200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RefuelShip200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RefuelShip200ResponseData> mapFromJson(dynamic json) {
    final map = <String, RefuelShip200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RefuelShip200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RefuelShip200ResponseData-objects as value to a dart map
  static Map<String, List<RefuelShip200ResponseData>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RefuelShip200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RefuelShip200ResponseData.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'agent',
    'fuel',
  };
}

