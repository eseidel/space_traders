/// A route between two systems.
class JumpPlan {
  /// Creates a route between two systems.
  JumpPlan(Iterable<String> route)
      : route = List.from(route),
        assert(route.length >= 2, 'Route must have at least two systems');

  /// The system where the route starts.
  String get fromSystem => route.first;

  /// The system where the route ends.
  String get toSystem => route.last;

  /// The systems that make up the route.
  final List<String> route;

  /// Returns a reversed copy of this route.
  JumpPlan reversed() => JumpPlan(route.reversed);
}

/// In memory cache of systems connected by jump gates.
class JumpCache {
  final List<JumpPlan> _plans = [];

  /// Check to see if a route exists between two systems.
  JumpPlan? lookupJumpPlan({
    required String fromSystem,
    required String toSystem,
  }) {
    for (final plan in _plans) {
      final fromIndex = plan.route.indexOf(fromSystem);
      if (fromIndex == -1) continue;
      final toIndex = plan.route.indexOf(toSystem);
      if (toIndex == -1) continue;
      if (fromIndex < toIndex) {
        return JumpPlan(plan.route.sublist(fromIndex, toIndex + 1));
      }
      if (fromIndex > toIndex) {
        return JumpPlan(
          plan.route.sublist(toIndex, fromIndex + 1).reversed.toList(),
        );
      }
    }
    return null;
  }

  /// Add a route between two systems.
  void addJumpPlan(JumpPlan plan) {
    _plans.add(plan);
  }
}
