import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Enum describing the type of action taken in a action in a route.
enum RouteActionType {
  /// Lets us have a RoutePlan which does nothing.
  /// Used by apis which ask "what route do I take to get to this waypoint?"
  /// and there is no action to take.
  emptyRoute,

  /// Jump between two jump gates.
  jump,

  /// Refuel at a the local market.
  refuel,

  /// Travel between two waypoints in the same system at drift speed.
  navDrift,

  /// Travel between two waypoints in the same system at cruise speed.
  navCruise;

  // NAV_BURN,
  // WARP_DRIFT,
  // WARP_CRUISE,

  /// Returns true if this action uses the reactor.
  bool usesReactor() {
    switch (this) {
      case RouteActionType.jump:
        return true;
      case RouteActionType.emptyRoute:
      case RouteActionType.navDrift:
      case RouteActionType.refuel:
      case RouteActionType.navCruise:
        return false;
    }
  }

  /// Number of requests this action expects to take to execute.
  int get requestCount {
    switch (this) {
      case RouteActionType.emptyRoute:
        return 0;
      case RouteActionType.jump:
      case RouteActionType.navCruise:
      case RouteActionType.navDrift:
        return 1;
      case RouteActionType.refuel:
        // Dock, refuel, undock.
        // Possibly even one more for fetching the market.
        return 3;
    }
  }
}

/// An action taken in a route.
@immutable
class RouteAction {
  /// Create a new route action.
  const RouteAction({
    required this.startSymbol,
    required this.endSymbol,
    required this.type,
    required this.seconds,
    required this.fuelUsed,
    // required this.cooldown,
  });

  /// Create a new route action from JSON.
  factory RouteAction.fromJson(Map<String, dynamic> json) {
    return RouteAction(
      startSymbol: WaypointSymbol.fromJson(json['startSymbol'] as String),
      endSymbol: WaypointSymbol.fromJson(json['endSymbol'] as String),
      type: RouteActionType.values.firstWhere(
        (e) => e.name == json['type'] as String,
      ),
      // Nullability can be removed later.
      seconds: json['seconds'] as int? ?? json['duration'] as int,
      fuelUsed: json['fuelUsed'] as int? ?? 0,
      // cooldown: json['cooldown'] as int,
    );
  }

  /// The symbol of the waypoint where this action starts.
  final WaypointSymbol startSymbol;

  /// The symbol of the waypoint where this action ends.
  final WaypointSymbol endSymbol;

  /// The type of action taken.
  final RouteActionType type;

  /// The duration of this action in seconds.
  final int seconds;
  // final int cooldown;

  /// The amount of fuel used during this action.
  final int fuelUsed;

  /// The duration of this action.
  Duration get duration => Duration(seconds: seconds);

  /// Returns true if this action uses the reactor.
  bool usesReactor() => type.usesReactor();

  /// Number of requests this action expects to take to execute.
  int get requestCount => type.requestCount;

  /// Convert this action to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startSymbol': startSymbol.toJson(),
        'endSymbol': endSymbol.toJson(),
        'type': type.name,
        'seconds': seconds,
        'fuelUsed': fuelUsed,
        // 'cooldown': cooldown,
      };

  @override
  String toString() {
    return '$startSymbol -> $endSymbol $type (${seconds}s)}';
  }
}

/// A plan for a route between two waypoints.
@immutable
class RoutePlan {
  /// Create a new route plan.
  const RoutePlan({
    required this.fuelCapacity,
    required this.shipSpeed,
    required this.actions,
    required this.fuelUsed,
  });

  /// Create a new empty route plan that does nothing.
  RoutePlan.empty({
    required WaypointSymbol symbol,
    required this.fuelCapacity,
    required this.shipSpeed,
  })  : actions = <RouteAction>[
          RouteAction(
            startSymbol: symbol,
            endSymbol: symbol,
            type: RouteActionType.jump,
            seconds: 0,
            fuelUsed: 0,
          ),
        ],
        fuelUsed = 0;

  /// Create a new route plan from JSON.
  factory RoutePlan.fromJson(Map<String, dynamic> json) {
    return RoutePlan(
      fuelCapacity: json['fuelCapacity'] as int,
      shipSpeed: json['shipSpeed'] as int,
      actions: (json['actions'] as List<dynamic>)
          .map((e) => RouteAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      fuelUsed: json['fuelUsed'] as int,
    );
  }

  /// The fuel capacity the route was planned for.
  final int fuelCapacity;

  /// The speed of the ship the route was planned for.
  final int shipSpeed;

  /// The total fuel used during this route.
  final int fuelUsed;

  /// The actions to take to travel between the two waypoints.
  final List<RouteAction> actions;

  /// The symbol of the waypoint where this route starts.
  WaypointSymbol get startSymbol => actions.first.startSymbol;

  /// The symbol of the waypoint where this route ends.
  WaypointSymbol get endSymbol => actions.last.endSymbol;

  /// The total time of this route in seconds.
  Duration get duration =>
      Duration(seconds: actions.fold<int>(0, (a, b) => a + b.seconds));

  /// The number of requests this route expects to take to execute.
  int get requestCount => actions.fold<int>(0, (a, b) => a + b.requestCount);

  /// Returns the next action to take from the given waypoint.
  RouteAction? nextActionFrom(WaypointSymbol waypointSymbol) {
    final index = actions.indexWhere((e) => e.startSymbol == waypointSymbol);
    if (index == -1) {
      return null;
    }
    return actions[index];
  }

  /// Returns the action after the given action or null if there is none.
  RouteAction? actionAfter(RouteAction action) {
    final index = actions.indexOf(action);
    if (index == -1) {
      throw ArgumentError('No action $action in $actions');
    }
    if (index + 1 >= actions.length) {
      return null;
    }
    return actions[index + 1];
  }

  /// Convert this route plan to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'fuelCapacity': fuelCapacity,
        'shipSpeed': shipSpeed,
        'actions': actions.map((e) => e.toJson()).toList(),
        'fuelUsed': fuelUsed,
      };
}
