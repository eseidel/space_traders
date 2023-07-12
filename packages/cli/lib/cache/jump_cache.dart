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
      if (plan.fromSystem == fromSystem && plan.toSystem == toSystem) {
        return plan;
      }
      if (plan.fromSystem == toSystem && plan.toSystem == fromSystem) {
        return plan.reversed();
      }
    }
    return null;
  }

  /// Add a route between two systems.
  void addJumpPlan(JumpPlan plan) {
    // TODO(eseidel): This could also cache each sub-segment of the path.
    // A-B-C could be cached as A-B, B-C, A-C.
    // Or the path lookup could find such.
    _plans.add(plan);
  }
}
