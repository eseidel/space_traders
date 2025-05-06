import 'package:meta/meta.dart';

@immutable
/// Stats about the galaxy.
class GalaxyStats {
  /// Creates a new [GalaxyStats].
  const GalaxyStats({required this.systemCount, required this.waypointCount});

  /// Number of systems in the galaxy.
  final int systemCount;

  /// Number of waypoints in the galaxy.
  final int waypointCount;
}
