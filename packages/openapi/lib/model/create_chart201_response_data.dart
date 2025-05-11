//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class CreateChart201ResponseData {
  /// Returns a new [CreateChart201ResponseData] instance.
  CreateChart201ResponseData({
    required this.chart,
    required this.waypoint,
    required this.transaction,
    required this.agent,
  });

  Chart chart;

  Waypoint waypoint;

  ChartTransaction transaction;

  Agent agent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateChart201ResponseData &&
          other.chart == chart &&
          other.waypoint == waypoint &&
          other.transaction == transaction &&
          other.agent == agent;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (chart.hashCode) +
      (waypoint.hashCode) +
      (transaction.hashCode) +
      (agent.hashCode);

  @override
  String toString() =>
      'CreateChart201ResponseData[chart=$chart, waypoint=$waypoint, transaction=$transaction, agent=$agent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'chart'] = this.chart;
    json[r'waypoint'] = this.waypoint;
    json[r'transaction'] = this.transaction;
    json[r'agent'] = this.agent;
    return json;
  }

  /// Returns a new [CreateChart201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateChart201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CreateChart201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CreateChart201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateChart201ResponseData(
        chart: Chart.fromJson(json[r'chart'])!,
        waypoint: Waypoint.fromJson(json[r'waypoint'])!,
        transaction: ChartTransaction.fromJson(json[r'transaction'])!,
        agent: Agent.fromJson(json[r'agent'])!,
      );
    }
    return null;
  }

  static List<CreateChart201ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateChart201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateChart201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateChart201ResponseData> mapFromJson(dynamic json) {
    final map = <String, CreateChart201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateChart201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateChart201ResponseData-objects as value to a dart map
  static Map<String, List<CreateChart201ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateChart201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateChart201ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'chart',
    'waypoint',
    'transaction',
    'agent',
  };
}
