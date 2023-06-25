//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Register201ResponseData {
  /// Returns a new [Register201ResponseData] instance.
  Register201ResponseData({
    required this.agent,
    required this.contract,
    required this.faction,
    required this.ship,
    required this.token,
  });

  Agent agent;

  Contract contract;

  Faction faction;

  Ship ship;

  /// A Bearer token for accessing secured API endpoints.
  String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Register201ResponseData &&
          other.agent == agent &&
          other.contract == contract &&
          other.faction == faction &&
          other.ship == ship &&
          other.token == token;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (agent.hashCode) +
      (contract.hashCode) +
      (faction.hashCode) +
      (ship.hashCode) +
      (token.hashCode);

  @override
  String toString() =>
      'Register201ResponseData[agent=$agent, contract=$contract, faction=$faction, ship=$ship, token=$token]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'agent'] = this.agent;
    json[r'contract'] = this.contract;
    json[r'faction'] = this.faction;
    json[r'ship'] = this.ship;
    json[r'token'] = this.token;
    return json;
  }

  /// Returns a new [Register201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Register201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Register201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Register201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Register201ResponseData(
        agent: Agent.fromJson(json[r'agent'])!,
        contract: Contract.fromJson(json[r'contract'])!,
        faction: Faction.fromJson(json[r'faction'])!,
        ship: Ship.fromJson(json[r'ship'])!,
        token: mapValueOfType<String>(json, r'token')!,
      );
    }
    return null;
  }

  static List<Register201ResponseData>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Register201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Register201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Register201ResponseData> mapFromJson(dynamic json) {
    final map = <String, Register201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Register201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Register201ResponseData-objects as value to a dart map
  static Map<String, List<Register201ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Register201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Register201ResponseData.listFromJson(
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
    'agent',
    'contract',
    'faction',
    'ship',
    'token',
  };
}
