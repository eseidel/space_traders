//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Chart {
  /// Returns a new [Chart] instance.
  Chart({
    required this.waypointSymbol,
    required this.submittedBy,
    required this.submittedOn,
  });

  /// The symbol of the waypoint.
  String waypointSymbol;

  /// The agent that submitted the chart for this waypoint.
  String submittedBy;

  /// The time the chart for this waypoint was submitted.
  DateTime submittedOn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chart &&
          other.waypointSymbol == waypointSymbol &&
          other.submittedBy == submittedBy &&
          other.submittedOn == submittedOn;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (waypointSymbol.hashCode) +
      (submittedBy.hashCode) +
      (submittedOn.hashCode);

  @override
  String toString() =>
      'Chart[waypointSymbol=$waypointSymbol, submittedBy=$submittedBy, submittedOn=$submittedOn]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'waypointSymbol'] = this.waypointSymbol;
    json[r'submittedBy'] = this.submittedBy;
    json[r'submittedOn'] = this.submittedOn.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Chart] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Chart? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Chart[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Chart[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Chart(
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
        submittedBy: mapValueOfType<String>(json, r'submittedBy')!,
        submittedOn: mapDateTime(json, r'submittedOn', r'')!,
      );
    }
    return null;
  }

  static List<Chart> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Chart>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Chart.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Chart> mapFromJson(dynamic json) {
    final map = <String, Chart>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Chart.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Chart-objects as value to a dart map
  static Map<String, List<Chart>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Chart>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Chart.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'waypointSymbol',
    'submittedBy',
    'submittedOn',
  };
}
