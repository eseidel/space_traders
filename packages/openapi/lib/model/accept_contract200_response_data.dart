//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class AcceptContract200ResponseData {
  /// Returns a new [AcceptContract200ResponseData] instance.
  AcceptContract200ResponseData({
    required this.agent,
    required this.contract,
  });

  Agent agent;

  Contract contract;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcceptContract200ResponseData &&
          other.agent == agent &&
          other.contract == contract;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (agent.hashCode) + (contract.hashCode);

  @override
  String toString() =>
      'AcceptContract200ResponseData[agent=$agent, contract=$contract]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'agent'] = this.agent;
    json[r'contract'] = this.contract;
    return json;
  }

  /// Returns a new [AcceptContract200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AcceptContract200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AcceptContract200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AcceptContract200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AcceptContract200ResponseData(
        agent: Agent.fromJson(json[r'agent'])!,
        contract: Contract.fromJson(json[r'contract'])!,
      );
    }
    return null;
  }

  static List<AcceptContract200ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AcceptContract200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AcceptContract200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AcceptContract200ResponseData> mapFromJson(dynamic json) {
    final map = <String, AcceptContract200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AcceptContract200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AcceptContract200ResponseData-objects as value to a dart map
  static Map<String, List<AcceptContract200ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AcceptContract200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AcceptContract200ResponseData.listFromJson(
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
    'contract',
  };
}
