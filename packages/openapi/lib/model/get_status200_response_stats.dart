class GetStatus200ResponseStats {
  GetStatus200ResponseStats({
    required this.agents,
    required this.ships,
    required this.systems,
    required this.waypoints,
    this.accounts,
  });

  factory GetStatus200ResponseStats.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetStatus200ResponseStats(
      accounts: json['accounts'] as int?,
      agents: json['agents'] as int,
      ships: json['ships'] as int,
      systems: json['systems'] as int,
      waypoints: json['waypoints'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseStats? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseStats.fromJson(json);
  }

  int? accounts;
  int agents;
  int ships;
  int systems;
  int waypoints;

  Map<String, dynamic> toJson() {
    return {
      'accounts': accounts,
      'agents': agents,
      'ships': ships,
      'systems': systems,
      'waypoints': waypoints,
    };
  }

  @override
  int get hashCode => Object.hash(accounts, agents, ships, systems, waypoints);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseStats &&
        accounts == other.accounts &&
        agents == other.agents &&
        ships == other.ships &&
        systems == other.systems &&
        waypoints == other.waypoints;
  }
}
