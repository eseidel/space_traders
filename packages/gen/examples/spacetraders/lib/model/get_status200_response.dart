import 'package:spacetraders/model/get_status200_response_announcements_item.dart';
import 'package:spacetraders/model/get_status200_response_health.dart';
import 'package:spacetraders/model/get_status200_response_leaderboards.dart';
import 'package:spacetraders/model/get_status200_response_links_item.dart';
import 'package:spacetraders/model/get_status200_response_server_resets.dart';
import 'package:spacetraders/model/get_status200_response_stats.dart';

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
    required this.announcements,
    required this.links,
  });

  factory GetStatus200Response.fromJson(Map<String, dynamic> json) {
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
          (json['announcements'] as List<dynamic>)
              .map<GetStatus200ResponseAnnouncementsItem>(
                (e) => GetStatus200ResponseAnnouncementsItem.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      links:
          (json['links'] as List<dynamic>)
              .map<GetStatus200ResponseLinksItem>(
                (e) => GetStatus200ResponseLinksItem.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  final String status;
  final String version;
  final String resetDate;
  final String description;
  final GetStatus200ResponseStats stats;
  final GetStatus200ResponseHealth health;
  final GetStatus200ResponseLeaderboards leaderboards;
  final GetStatus200ResponseServerResets serverResets;
  final List<GetStatus200ResponseAnnouncementsItem> announcements;
  final List<GetStatus200ResponseLinksItem> links;

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
}
