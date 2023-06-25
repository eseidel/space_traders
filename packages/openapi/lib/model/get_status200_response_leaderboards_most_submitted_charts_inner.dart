//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetStatus200ResponseLeaderboardsMostSubmittedChartsInner {
  /// Returns a new [GetStatus200ResponseLeaderboardsMostSubmittedChartsInner] instance.
  GetStatus200ResponseLeaderboardsMostSubmittedChartsInner({
    required this.agentSymbol,
    required this.chartCount,
  });

  /// Symbol of the agent.
  String agentSymbol;

  /// Amount of charts done by the agent.
  int chartCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200ResponseLeaderboardsMostSubmittedChartsInner &&
          other.agentSymbol == agentSymbol &&
          other.chartCount == chartCount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (agentSymbol.hashCode) + (chartCount.hashCode);

  @override
  String toString() =>
      'GetStatus200ResponseLeaderboardsMostSubmittedChartsInner[agentSymbol=$agentSymbol, chartCount=$chartCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'agentSymbol'] = this.agentSymbol;
    json[r'chartCount'] = this.chartCount;
    return json;
  }

  /// Returns a new [GetStatus200ResponseLeaderboardsMostSubmittedChartsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetStatus200ResponseLeaderboardsMostSubmittedChartsInner? fromJson(
      dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetStatus200ResponseLeaderboardsMostSubmittedChartsInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetStatus200ResponseLeaderboardsMostSubmittedChartsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetStatus200ResponseLeaderboardsMostSubmittedChartsInner(
        agentSymbol: mapValueOfType<String>(json, r'agentSymbol')!,
        chartCount: mapValueOfType<int>(json, r'chartCount')!,
      );
    }
    return null;
  }

  static List<GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>?
      listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value =
            GetStatus200ResponseLeaderboardsMostSubmittedChartsInner.fromJson(
                row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>
      mapFromJson(dynamic json) {
    final map =
        <String, GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            GetStatus200ResponseLeaderboardsMostSubmittedChartsInner.fromJson(
                entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetStatus200ResponseLeaderboardsMostSubmittedChartsInner-objects as value to a dart map
  static Map<String,
          List<GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String,
        List<GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseLeaderboardsMostSubmittedChartsInner
            .listFromJson(
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
    'agentSymbol',
    'chartCount',
  };
}
