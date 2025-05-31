import 'package:openapi/model/get_status200_response_announcements_inner.dart';
import 'package:openapi/model/get_status200_response_health.dart';
import 'package:openapi/model/get_status200_response_leaderboards.dart';
import 'package:openapi/model/get_status200_response_links_inner.dart';
import 'package:openapi/model/get_status200_response_server_resets.dart';
import 'package:openapi/model/get_status200_response_stats.dart';
import 'package:openapi/model_helpers.dart';

class GetStatus200Response {
  GetStatus200Response({
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

  factory GetStatus200Response.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetStatus200Response(
      status: json['status'] as String,
      version: json['version'] as String,
      resetDate: json['resetDate'] as String,
      description: json['description'] as String,
      stats: GetStatus200ResponseStats.fromJson(
        json['stats'] as Map<String, dynamic>,
      ),
      health: GetStatus200ResponseHealth.fromJson(
        json['health'] as Map<String, dynamic>,
      ),
      leaderboards: GetStatus200ResponseLeaderboards.fromJson(
        json['leaderboards'] as Map<String, dynamic>,
      ),
      serverResets: GetStatus200ResponseServerResets.fromJson(
        json['serverResets'] as Map<String, dynamic>,
      ),
      announcements:
          (json['announcements'] as List)
              .map<GetStatus200ResponseAnnouncementsInner>(
                (e) => GetStatus200ResponseAnnouncementsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      links:
          (json['links'] as List)
              .map<GetStatus200ResponseLinksInner>(
                (e) => GetStatus200ResponseLinksInner.fromJson(
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

  String status;
  String version;
  String resetDate;
  String description;
  GetStatus200ResponseStats stats;
  GetStatus200ResponseHealth health;
  GetStatus200ResponseLeaderboards leaderboards;
  GetStatus200ResponseServerResets serverResets;
  List<GetStatus200ResponseAnnouncementsInner> announcements;
  List<GetStatus200ResponseLinksInner> links;

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
  int get hashCode => Object.hash(
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
  );

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
