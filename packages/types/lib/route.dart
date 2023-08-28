import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Enum describing the type of action taken in a action in a route.
enum RouteActionType {
  /// Jump between two jump gates.
  jump,
  // REFUEL,
  // NAV_DRIFT,
  // NAV_BURN,
  /// Travel between two waypoints in the same system at cruise speed.
  navCruise;
  // WARP_DRIFT,
  // WARP_CRUISE,

  /// Returns true if this action uses the reactor.
  bool usesReactor() {
    switch (this) {
      case RouteActionType.jump:
        return true;
      case RouteActionType.navCruise:
        return false;
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
    required this.duration,
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
      duration: json['duration'] as int,
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
  final int duration;
  // final int cooldown;

  /// Returns true if this action uses the reactor.
  bool usesReactor() => type.usesReactor();

  /// Convert this action to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startSymbol': startSymbol.toJson(),
        'endSymbol': endSymbol.toJson(),
        'type': type.name,
        'duration': duration,
        // 'cooldown': cooldown,
      };
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
      Duration(seconds: actions.fold<int>(0, (a, b) => a + b.duration));

  /// Returns the next action to take from the given waypoint.
  RouteAction nextActionFrom(WaypointSymbol waypointSymbol) {
    final index = actions.indexWhere((e) => e.startSymbol == waypointSymbol);
    if (index == -1) {
      throw ArgumentError('No action starting from $waypointSymbol');
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
