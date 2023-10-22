import 'package:types/types.dart';

enum AttributionType {
  unknown,
  overhead,
  ship,
}

/// Attribution records the start/stop of a cycle of work.
/// BehaviorState captures the state needed to do the work.
/// Behavior is the enum representing the type of work being done.
/// The start/stop times can be cross-referenced to the transactions
/// cache to find how many credits were made during the cycle.
/// The number of requests can then be used to compute the credits/request.
class Attribution {
  /// Attribution.unknown() is used for any work that is not attributed.
  Attribution.unknown()
      : type = AttributionType.unknown,
        shipSymbol = null,
        behavior = null,
        start = DateTime.timestamp(),
        stop = null;

  /// Attribution.overhead() is used for any work that is expected, but
  /// not specific to a ship.
  Attribution.overhead()
      : type = AttributionType.overhead,
        shipSymbol = null,
        behavior = null,
        start = DateTime.timestamp(),
        stop = null;

  /// Attribution.ship() is used for any work that is specific to a ship.
  Attribution.ship({required this.shipSymbol, required this.behavior})
      : type = AttributionType.ship,
        start = DateTime.timestamp(),
        stop = null;

  /// The type of attribution.
  final AttributionType type;

  /// The ship that this work was for.
  final ShipSymbol? shipSymbol;

  /// The type of work being done.
  final Behavior? behavior;

  /// The start time of the attribution.
  final DateTime start;

  /// The stop time of the attribution.
  DateTime? stop;

  /// Server requests made during the attribution.
  final List<String> requests = [];

  /// Add a request to the attribution.
  void addRequest(String request) {
    requests.add(request);
  }

  /// Exit the attribution.
  void exit() {
    stop = DateTime.timestamp();
  }
}

/// Convenience function to run a callback with an attribution.
T runWithAttribution<T>(Attribution attribution, T Function() callback) {
  AttributionStack.enter(attribution);
  try {
    return callback();
  } finally {
    AttributionStack.exit(attribution);
  }
}

/// AttributionStack is a stack of attributions.
class AttributionStack {
  /// The stack of attributions.
  static final List<Attribution> _attributions = [];

  /// The unknown attribution.
  static final Attribution _unknown = Attribution.unknown();

  /// The current attribution.
  static Attribution? get current {
    if (_attributions.isEmpty) {
      return _unknown;
    }
    return _attributions.last;
  }

  /// Enter a new attribution.
  static void enter(Attribution attribution) {
    _attributions.add(attribution);
  }

  /// Exit an attribution.
  static void exit(Attribution attribution) {
    if (current != attribution) {
      throw Exception('AttributionStack: exit: current != attribution');
    }
    _attributions.removeLast().exit();
  }
}
