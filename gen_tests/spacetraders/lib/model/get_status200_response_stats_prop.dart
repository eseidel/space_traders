import 'package:meta/meta.dart';

@immutable
class GetStatus200ResponseStatsProp {
  const GetStatus200ResponseStatsProp({
    required this.agents,
    required this.ships,
    required this.systems,
    required this.waypoints,
    this.accounts,
  });

  factory GetStatus200ResponseStatsProp.fromJson(Map<String, dynamic> json) {
    return GetStatus200ResponseStatsProp(
      accounts: json['accounts'] as int?,
      agents: json['agents'] as int,
      ships: json['ships'] as int,
      systems: json['systems'] as int,
      waypoints: json['waypoints'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseStatsProp? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseStatsProp.fromJson(json);
  }

  final int? accounts;
  final int agents;
  final int ships;
  final int systems;
  final int waypoints;

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
  int get hashCode =>
      Object.hashAll([accounts, agents, ships, systems, waypoints]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetStatus200ResponseStatsProp &&
        accounts == other.accounts &&
        agents == other.agents &&
        ships == other.ships &&
        systems == other.systems &&
        waypoints == other.waypoints;
  }
}
