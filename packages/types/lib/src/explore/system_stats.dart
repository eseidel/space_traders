import 'package:json_annotation/json_annotation.dart';
import 'package:types/types.dart';

part 'system_stats.g.dart';

/// Stats about the systems we have explored, charted and cached.
@JsonSerializable()
class SystemStats {
  /// Create a new instance of [SystemStats].
  SystemStats({
    required this.startSystem,
    required this.totalSystems,
    required this.totalWaypoints,
    required this.totalJumpgates,
    required this.reachableSystems,
    required this.reachableWaypoints,
    required this.reachableMarkets,
    required this.reachableShipyards,
    required this.reachableAsteroids,
    required this.reachableJumpGates,
    required this.chartedWaypoints,
    required this.chartedAsteroids,
    required this.chartedJumpGates,
    required this.cachedJumpGates,
  });

  /// Create a new instance of [SystemStats] from JSON.
  factory SystemStats.fromJson(Map<String, dynamic> json) =>
      _$SystemStatsFromJson(json);

  /// The the system we started in for collecting this data.
  final SystemSymbol startSystem;

  /// Total known systems (including not reachable from the start system).
  final int totalSystems;

  /// Total known waypoints (including not reachable from the start system).
  final int totalWaypoints;

  /// Total known jumpgates (including not reachable from the start system).
  final int totalJumpgates;

  /// Systems known reachable from the start system.
  final int reachableSystems;

  /// Waypoints known reachable from the start system.
  final int reachableWaypoints;

  /// Markets known reachable from the start system.
  final int reachableMarkets;

  /// Shipyards known reachable from the start system.
  final int reachableShipyards;

  /// Asteroids known reachable from the start system.
  /// Only used for computing how much of charting went into asteroids.
  final int reachableAsteroids;

  /// Jumpgates known reachable from the start system.
  final int reachableJumpGates;

  /// Number of waypoints we know to be charted (including by others).
  final int chartedWaypoints;

  /// Number of asteroids we know to be charted (including by others).
  final int chartedAsteroids;

  /// Number of jumpgates we know to be charted (including by others).
  final int chartedJumpGates;

  /// Number of jumpgate objects we have cached.
  final int cachedJumpGates;

  /// Percentage of charts that are asteroids.
  /// Asteroids are always(?) baren, so rarely worth visiting or charting.
  double get asteroidChartPercent => chartedAsteroids / reachableAsteroids;

  /// Percentage of charts that are non-asteroids.
  double get nonAsteroidChartPercent =>
      (chartedWaypoints - chartedAsteroids) /
      (reachableWaypoints - reachableAsteroids);

  /// Percentage of systems that are reachable from the start system.
  double get reachableSystemPercent => reachableSystems / totalSystems;

  /// Percentage of waypoints that are reachable from the start system.
  double get reachableWaypointPercent => reachableWaypoints / totalWaypoints;

  /// Percentage of markets that are reachable from the start system.
  double get reachableJumpGatePercent => reachableJumpGates / totalJumpgates;

  /// Convert this object to JSON.
  Map<String, dynamic> toJson() => _$SystemStatsToJson(this);
}
