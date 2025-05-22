class GetStatus200Response {
  GetStatus200Response({
    required this.status,
    required this.version,
    required this.resetDate,
    required this.description,
    required this.stats,
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
      leaderboards: GetStatus200ResponseLeaderboards.fromJson(
        json['leaderboards'] as Map<String, dynamic>,
      ),
      serverResets: GetStatus200ResponseServerResets.fromJson(
        json['serverResets'] as Map<String, dynamic>,
      ),
      announcements: (json['announcements'] as List<dynamic>)
          .map<GetStatus200ResponseAnnouncementsInner>(
            (e) => GetStatus200ResponseAnnouncementsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      links: (json['links'] as List<dynamic>)
          .map<GetStatus200ResponseLinksInner>(
            (e) => GetStatus200ResponseLinksInner.fromJson(
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
  final GetStatus200ResponseLeaderboards leaderboards;
  final GetStatus200ResponseServerResets serverResets;
  final List<GetStatus200ResponseAnnouncementsInner> announcements;
  final List<GetStatus200ResponseLinksInner> links;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'version': version,
      'resetDate': resetDate,
      'description': description,
      'stats': stats.toJson(),
      'leaderboards': leaderboards.toJson(),
      'serverResets': serverResets.toJson(),
      'announcements': announcements.map((e) => e.toJson()).toList(),
      'links': links.map((e) => e.toJson()).toList(),
    };
  }
}

class GetStatus200ResponseStats {
  GetStatus200ResponseStats({
    required this.agents,
    required this.ships,
    required this.systems,
    required this.waypoints,
  });

  factory GetStatus200ResponseStats.fromJson(Map<String, dynamic> json) {
    return GetStatus200ResponseStats(
      agents: json['agents'] as int,
      ships: json['ships'] as int,
      systems: json['systems'] as int,
      waypoints: json['waypoints'] as int,
    );
  }

  final int agents;
  final int ships;
  final int systems;
  final int waypoints;

  Map<String, dynamic> toJson() {
    return {
      'agents': agents,
      'ships': ships,
      'systems': systems,
      'waypoints': waypoints,
    };
  }
}

class GetStatus200ResponseLeaderboards {
  GetStatus200ResponseLeaderboards({
    required this.mostCredits,
    required this.mostSubmittedCharts,
  });

  factory GetStatus200ResponseLeaderboards.fromJson(Map<String, dynamic> json) {
    return GetStatus200ResponseLeaderboards(
      mostCredits: (json['mostCredits'] as List<dynamic>)
          .map<GetStatus200ResponseLeaderboardsMostCreditsInner>(
            (e) => GetStatus200ResponseLeaderboardsMostCreditsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      mostSubmittedCharts: (json['mostSubmittedCharts'] as List<dynamic>)
          .map<GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>(
            (e) => GetStatus200ResponseLeaderboardsMostSubmittedChartsInner
                .fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final List<GetStatus200ResponseLeaderboardsMostCreditsInner> mostCredits;
  final List<GetStatus200ResponseLeaderboardsMostSubmittedChartsInner>
      mostSubmittedCharts;

  Map<String, dynamic> toJson() {
    return {
      'mostCredits': mostCredits.map((e) => e.toJson()).toList(),
      'mostSubmittedCharts':
          mostSubmittedCharts.map((e) => e.toJson()).toList(),
    };
  }
}

class GetStatus200ResponseLeaderboardsMostCreditsInner {
  GetStatus200ResponseLeaderboardsMostCreditsInner({
    required this.agentSymbol,
    required this.credits,
  });

  factory GetStatus200ResponseLeaderboardsMostCreditsInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseLeaderboardsMostCreditsInner(
      agentSymbol: json['agentSymbol'] as String,
      credits: json['credits'] as int,
    );
  }

  final String agentSymbol;
  final int credits;

  Map<String, dynamic> toJson() {
    return {
      'agentSymbol': agentSymbol,
      'credits': credits,
    };
  }
}

class GetStatus200ResponseLeaderboardsMostSubmittedChartsInner {
  GetStatus200ResponseLeaderboardsMostSubmittedChartsInner({
    required this.agentSymbol,
    required this.chartCount,
  });

  factory GetStatus200ResponseLeaderboardsMostSubmittedChartsInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseLeaderboardsMostSubmittedChartsInner(
      agentSymbol: json['agentSymbol'] as String,
      chartCount: json['chartCount'] as int,
    );
  }

  final String agentSymbol;
  final int chartCount;

  Map<String, dynamic> toJson() {
    return {
      'agentSymbol': agentSymbol,
      'chartCount': chartCount,
    };
  }
}

class GetStatus200ResponseServerResets {
  GetStatus200ResponseServerResets({
    required this.next,
    required this.frequency,
  });

  factory GetStatus200ResponseServerResets.fromJson(Map<String, dynamic> json) {
    return GetStatus200ResponseServerResets(
      next: json['next'] as String,
      frequency: json['frequency'] as String,
    );
  }

  final String next;
  final String frequency;

  Map<String, dynamic> toJson() {
    return {
      'next': next,
      'frequency': frequency,
    };
  }
}

class GetStatus200ResponseAnnouncementsInner {
  GetStatus200ResponseAnnouncementsInner({
    required this.title,
    required this.body,
  });

  factory GetStatus200ResponseAnnouncementsInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return GetStatus200ResponseAnnouncementsInner(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  final String title;
  final String body;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
    };
  }
}

class GetStatus200ResponseLinksInner {
  GetStatus200ResponseLinksInner({
    required this.name,
    required this.url,
  });

  factory GetStatus200ResponseLinksInner.fromJson(Map<String, dynamic> json) {
    return GetStatus200ResponseLinksInner(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  final String name;
  final String url;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}
