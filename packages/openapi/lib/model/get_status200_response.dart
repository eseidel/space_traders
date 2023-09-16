//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetStatus200Response {
  /// Returns a new [GetStatus200Response] instance.
  GetStatus200Response({
    required this.status,
    required this.version,
    required this.resetDate,
    required this.description,
    required this.stats,
    required this.leaderboards,
    required this.serverResets,
    this.announcements = const [],
    this.links = const [],
  });

  /// The current status of the game server.
  String status;

  /// The current version of the API.
  String version;

  /// The date when the game server was last reset.
  String resetDate;

  String description;

  GetStatus200ResponseStats stats;

  GetStatus200ResponseLeaderboards leaderboards;

  GetStatus200ResponseServerResets serverResets;

  List<GetStatus200ResponseAnnouncementsInner> announcements;

  List<GetStatus200ResponseLinksInner> links;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200Response &&
          other.status == status &&
          other.version == version &&
          other.resetDate == resetDate &&
          other.description == description &&
          other.stats == stats &&
          other.leaderboards == leaderboards &&
          other.serverResets == serverResets &&
          other.announcements == announcements &&
          other.links == links;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (status.hashCode) +
      (version.hashCode) +
      (resetDate.hashCode) +
      (description.hashCode) +
      (stats.hashCode) +
      (leaderboards.hashCode) +
      (serverResets.hashCode) +
      (announcements.hashCode) +
      (links.hashCode);

  @override
  String toString() =>
      'GetStatus200Response[status=$status, version=$version, resetDate=$resetDate, description=$description, stats=$stats, leaderboards=$leaderboards, serverResets=$serverResets, announcements=$announcements, links=$links]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'status'] = this.status;
    json[r'version'] = this.version;
    json[r'resetDate'] = this.resetDate;
    json[r'description'] = this.description;
    json[r'stats'] = this.stats;
    json[r'leaderboards'] = this.leaderboards;
    json[r'serverResets'] = this.serverResets;
    json[r'announcements'] = this.announcements;
    json[r'links'] = this.links;
    return json;
  }

  /// Returns a new [GetStatus200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetStatus200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetStatus200Response[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetStatus200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetStatus200Response(
        status: mapValueOfType<String>(json, r'status')!,
        version: mapValueOfType<String>(json, r'version')!,
        resetDate: mapValueOfType<String>(json, r'resetDate')!,
        description: mapValueOfType<String>(json, r'description')!,
        stats: GetStatus200ResponseStats.fromJson(json[r'stats'])!,
        leaderboards:
            GetStatus200ResponseLeaderboards.fromJson(json[r'leaderboards'])!,
        serverResets:
            GetStatus200ResponseServerResets.fromJson(json[r'serverResets'])!,
        announcements: GetStatus200ResponseAnnouncementsInner.listFromJson(
            json[r'announcements']),
        links: GetStatus200ResponseLinksInner.listFromJson(json[r'links']),
      );
    }
    return null;
  }

  static List<GetStatus200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetStatus200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetStatus200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetStatus200Response> mapFromJson(dynamic json) {
    final map = <String, GetStatus200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetStatus200Response-objects as value to a dart map
  static Map<String, List<GetStatus200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetStatus200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetStatus200Response.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'version',
    'resetDate',
    'description',
    'stats',
    'leaderboards',
    'serverResets',
    'announcements',
    'links',
  };
}
