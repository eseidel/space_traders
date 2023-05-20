//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class GetStatus200ResponseLeaderboards {
  /// Returns a new [GetStatus200ResponseLeaderboards] instance.
  GetStatus200ResponseLeaderboards({
    this.mostCredits = const [],
    this.mostSubmittedCharts = const [],
  });

  List<GetStatus200ResponseLeaderboardsMostCreditsInner> mostCredits;

  List<GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>
      mostSubmittedCharts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200ResponseLeaderboards &&
          other.mostCredits == mostCredits &&
          other.mostSubmittedCharts == mostSubmittedCharts;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (mostCredits.hashCode) + (mostSubmittedCharts.hashCode);

  @override
  String toString() =>
      'GetStatus200ResponseLeaderboards[mostCredits=$mostCredits, mostSubmittedCharts=$mostSubmittedCharts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'mostCredits'] = this.mostCredits;
    json[r'mostSubmittedCharts'] = this.mostSubmittedCharts;
    return json;
  }

  /// Returns a new [GetStatus200ResponseLeaderboards] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetStatus200ResponseLeaderboards? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetStatus200ResponseLeaderboards[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetStatus200ResponseLeaderboards[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetStatus200ResponseLeaderboards(
        mostCredits:
            GetStatus200ResponseLeaderboardsMostCreditsInner.listFromJson(
                json[r'mostCredits'])!,
        mostSubmittedCharts:
            GetStatus200ResponseLeaderboardsMostSubmittedChartsInner
                .listFromJson(json[r'mostSubmittedCharts'])!,
      );
    }
    return null;
  }

  static List<GetStatus200ResponseLeaderboards>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetStatus200ResponseLeaderboards>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetStatus200ResponseLeaderboards.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetStatus200ResponseLeaderboards> mapFromJson(
      dynamic json) {
    final map = <String, GetStatus200ResponseLeaderboards>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseLeaderboards.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetStatus200ResponseLeaderboards-objects as value to a dart map
  static Map<String, List<GetStatus200ResponseLeaderboards>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetStatus200ResponseLeaderboards>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseLeaderboards.listFromJson(
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
    'mostCredits',
    'mostSubmittedCharts',
  };
}
