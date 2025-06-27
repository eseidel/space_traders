import 'package:meta/meta.dart';
import 'package:spacetraders/model/get_status200_response_announcements_prop_inner.dart';
import 'package:spacetraders/model/get_status200_response_health_prop.dart';
import 'package:spacetraders/model/get_status200_response_leaderboards_prop.dart';
import 'package:spacetraders/model/get_status200_response_links_prop_inner.dart';
import 'package:spacetraders/model/get_status200_response_server_resets_prop.dart';
import 'package:spacetraders/model/get_status200_response_stats_prop.dart';
import 'package:spacetraders/model_helpers.dart';

@immutable
class GetStatus200Response {
  const GetStatus200Response({
    required this.status,
    required this.version,
    required this.resetDate,
    required this.description,
    required this.stats,
    required this.health,
    required this.leaderboards,
    required this.serverResets,
    this.announcements = const [],
    this.links = const [],
  });

  factory GetStatus200Response.fromJson(Map<String, dynamic> json) {
    return GetStatus200Response(
      status: json['status'] as String,
      version: json['version'] as String,
      resetDate: json['resetDate'] as String,
      description: json['description'] as String,
      stats: GetStatus200ResponseStatsProp.fromJson(
        json['stats'] as Map<String, dynamic>,
      ),
      health: GetStatus200ResponseHealthProp.fromJson(
        json['health'] as Map<String, dynamic>,
      ),
      leaderboards: GetStatus200ResponseLeaderboardsProp.fromJson(
        json['leaderboards'] as Map<String, dynamic>,
      ),
      serverResets: GetStatus200ResponseServerResetsProp.fromJson(
        json['serverResets'] as Map<String, dynamic>,
      ),
      announcements: (json['announcements'] as List)
          .map<GetStatus200ResponseAnnouncementsPropInner>(
            (e) => GetStatus200ResponseAnnouncementsPropInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      links: (json['links'] as List)
          .map<GetStatus200ResponseLinksPropInner>(
            (e) => GetStatus200ResponseLinksPropInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200Response? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetStatus200Response.fromJson(json);
  }

  final String status;
  final String version;
  final String resetDate;
  final String description;
  final GetStatus200ResponseStatsProp stats;
  final GetStatus200ResponseHealthProp health;
  final GetStatus200ResponseLeaderboardsProp leaderboards;
  final GetStatus200ResponseServerResetsProp serverResets;
  final List<GetStatus200ResponseAnnouncementsPropInner> announcements;
  final List<GetStatus200ResponseLinksPropInner> links;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'version': version,
      'resetDate': resetDate,
      'description': description,
      'stats': stats.toJson(),
      'health': health.toJson(),
      'leaderboards': leaderboards.toJson(),
      'serverResets': serverResets.toJson(),
      'announcements': announcements.map((e) => e.toJson()).toList(),
      'links': links.map((e) => e.toJson()).toList(),
    };
  }

  @override
  int get hashCode => Object.hashAll([
    status,
    version,
    resetDate,
    description,
    stats,
    health,
    leaderboards,
    serverResets,
    announcements,
    links,
  ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200Response &&
        status == other.status &&
        version == other.version &&
        resetDate == other.resetDate &&
        description == other.description &&
        stats == other.stats &&
        health == other.health &&
        leaderboards == other.leaderboards &&
        serverResets == other.serverResets &&
        listsEqual(announcements, other.announcements) &&
        listsEqual(links, other.links);
  }
}
