import 'dart:math';

import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/system_pathing.dart';
import 'package:cli/printing.dart';
import 'package:meta/meta.dart';

// https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
/// Returns the fuel used for with a flight mode and the given distance.
int fuelUsedByDistance(
  int distance,
  ShipNavFlightMode flightMode,
) {
  switch (flightMode) {
    case ShipNavFlightMode.DRIFT:
      return 1;
    case ShipNavFlightMode.STEALTH:
      return distance;
    case ShipNavFlightMode.CRUISE:
      return distance;
    case ShipNavFlightMode.BURN:
      return 2 * distance;
  }
  throw UnimplementedError('Unknown flight mode: $flightMode');
}

/// Returns the fuel cost to the given waypoint.
int fuelUsedWithinSystem(
  SystemWaypoint a,
  SystemWaypoint b, {
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final distance = a.distanceTo(b);
  return fuelUsedByDistance(distance, flightMode);
}

double _speedMultiplier(ShipNavFlightMode flightMode) {
  switch (flightMode) {
    case ShipNavFlightMode.CRUISE:
      return 15;
    case ShipNavFlightMode.DRIFT:
      return 150;
    case ShipNavFlightMode.BURN:
      return 7.5;
    case ShipNavFlightMode.STEALTH:
      throw UnimplementedError('STEALTH speed multiplier not implemented');
  }
  throw UnimplementedError('Unknown flight mode: $flightMode');
}

// https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
/// Returns the flight time to the given distance.
int flightTimeByDistanceAndSpeed(
  double distance,
  int shipSpeed,
  ShipNavFlightMode flightMode,
) {
  return (distance.roundToDouble() *
              (_speedMultiplier(flightMode) / shipSpeed) +
          15)
      .round();
}

/// Returns the flight time to the given waypoint.
int flightTimeWithinSystemInSeconds(
  SystemWaypoint a,
  SystemWaypoint b, {
  required int shipSpeed,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  // TODO(eseidel): We should move to double distances.
  final distance = a.distanceTo(b).toDouble();
  return flightTimeByDistanceAndSpeed(distance, shipSpeed, flightMode);
}

/// Returns the cooldown time after jumping a given distance.
int cooldownTimeForJumpDistance(int distance) {
  if (distance < 0) {
    throw ArgumentError('Distance $distance is negative.');
  }
  if (distance > 2000) {
    throw ArgumentError('Distance $distance is too far to jump.');
  }
  return max(60, (distance / 10).round());
}

/// Returns the cooldown time after jumping between two systems.
int cooldownTimeForJumpBetweenSystems(System a, System b) {
  if (a.symbol == b.symbol) {
    throw ArgumentError('Cannot jump between the same system ${a.symbol}.');
  }
  final distance = a.distanceTo(b);
  if (distance > 2000) {
    throw ArgumentError(
      'Distance ${a.symbol} to ${b.symbol} is too far $distance to jump.',
    );
  }
  // This would need to check that this two are connected by a jumpgate.
  return max(60, (distance / 10).round());
}

/// Enum describing the type of action taken in a action in a route.
enum RouteActionType {
  /// Jump between two jump gates.
  jump,
  // REFUEL,
  // NAV_DRIFT,
  // NAV_BURN,
  /// Travel between two waypoints in the same system at cruise speed.
  navCruise,
  // WARP_DRIFT,
  // WARP_CRUISE,
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
      startSymbol: json['startSymbol'] as String,
      endSymbol: json['endSymbol'] as String,
      type: RouteActionType.values.firstWhere(
        (e) => e.name == json['type'] as String,
      ),
      duration: json['duration'] as int,
      // cooldown: json['cooldown'] as int,
    );
  }

  /// The symbol of the waypoint where this action starts.
  final String startSymbol;

  /// The symbol of the waypoint where this action ends.
  final String endSymbol;

  /// The type of action taken.
  final RouteActionType type;

  /// The duration of this action in seconds.
  final int duration;
  // final int cooldown;

  /// Convert this action to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'startSymbol': startSymbol,
        'endSymbol': endSymbol,
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
  String get startSymbol => actions.first.startSymbol;

  /// The symbol of the waypoint where this route ends.
  String get endSymbol => actions.last.endSymbol;

  /// The total time of this route in seconds.
  int get duration => actions.fold<int>(0, (a, b) => a + b.duration);

  /// Returns the next action to take from the given waypoint.
  RouteAction nextActionFrom(String waypointSymbol) {
    final index = actions.indexWhere((e) => e.startSymbol == waypointSymbol);
    if (index == -1) {
      throw ArgumentError('No action starting from $waypointSymbol');
    }
    return actions[index];
  }

  /// Makes a new route plan starting from the given waypoint.
  RoutePlan subPlanStartingFrom(
    SystemsCache systemsCache,
    String waypointSymbol,
  ) {
    final index = actions.indexWhere((e) => e.startSymbol == waypointSymbol);
    // This most commonly occurs when something asks for the endSymbol.
    if (index == -1) {
      throw ArgumentError('No action starting from $waypointSymbol');
    }
    final newActions = actions.sublist(index);
    final fuelUsed = _fuelUsedByActions(
      systemsCache,
      newActions,
    );
    return RoutePlan(
      fuelCapacity: fuelCapacity,
      shipSpeed: shipSpeed,
      actions: newActions,
      fuelUsed: fuelUsed,
    );
  }

  /// Convert this route plan to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'fuelCapacity': fuelCapacity,
        'shipSpeed': shipSpeed,
        'actions': actions.map((e) => e.toJson()).toList(),
        'fuelUsed': fuelUsed,
      };
}

/// Plan a route between two waypoints using a pre-computed jump plan.
RoutePlan routePlanFromJumpPlan(
  SystemsCache systemsCache, {
  required SystemWaypoint start,
  required SystemWaypoint end,
  required JumpPlan jumpPlan,
  required int fuelCapacity,
  required int shipSpeed,
}) {
  final actions = <RouteAction>[];
  if (jumpPlan.route.first != start.systemSymbol) {
    throw ArgumentError('Jump plan does not start at ${start.systemSymbol}');
  }
  if (jumpPlan.route.last != end.systemSymbol) {
    throw ArgumentError('Jump plan does not end at ${end.systemSymbol}');
  }
  final startJumpGate =
      systemsCache.jumpGateWaypointForSystem(start.systemSymbol)!;
  if (startJumpGate.symbol != start.symbol) {
    actions.add(_navigationAction(start, startJumpGate, shipSpeed));
  }

  for (var i = 0; i < jumpPlan.route.length - 1; i++) {
    final startSymbol = jumpPlan.route[i];
    final endSymbol = jumpPlan.route[i + 1];
    final startJumpgate = systemsCache.jumpGateWaypointForSystem(startSymbol)!;
    final endJumpGate = systemsCache.jumpGateWaypointForSystem(endSymbol)!;
    final isLastJump = i == jumpPlan.route.length - 2;
    actions.add(
      _jumpAction(
        systemsCache,
        startJumpgate,
        endJumpGate,
        shipSpeed,
        isLastJump: isLastJump,
      ),
    );
  }
  final endJumpGate = systemsCache.jumpGateWaypointForSystem(end.systemSymbol)!;
  if (endJumpGate.symbol != end.symbol) {
    actions.add(_navigationAction(endJumpGate, end, shipSpeed));
  }

  final fuelUsed = _fuelUsedByActions(systemsCache, actions);
  return RoutePlan(
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    actions: actions,
    fuelUsed: fuelUsed,
  );
}

class _JumpPlanBuilder {
  _JumpPlanBuilder();

  final List<String> _systems = [];

  bool get isNotEmpty => _systems.isNotEmpty;

  void addWaypoint(String waypointSymbol) {
    final system = parseWaypointString(waypointSymbol).system;
    _systems.add(system);
  }

  JumpPlan build() {
    final plan = JumpPlan(_systems);
    _systems.clear();
    return plan;
  }
}

void _saveJumpsInCache(JumpCache jumpCache, List<RouteAction> actions) {
  // Walk through actions, find any jump sequences, turn those into JumpPlans
  // which are then given to the JumpCache.
  final builder = _JumpPlanBuilder();
  for (var i = 0; i < actions.length; i++) {
    final action = actions[i];
    if (action.type == RouteActionType.jump) {
      builder.addWaypoint(action.startSymbol);
    } else {
      if (builder.isNotEmpty) {
        builder.addWaypoint(action.startSymbol);
        jumpCache.addJumpPlan(builder.build());
      }
    }
  }
  // This only happens when the last action is a jump e.g. we're at a jumpgate.
  if (builder.isNotEmpty) {
    builder.addWaypoint(actions.last.endSymbol);
    jumpCache.addJumpPlan(builder.build());
  }
}

RouteAction _navigationAction(
  SystemWaypoint start,
  SystemWaypoint end,
  int shipSpeed,
) {
  final duration = flightTimeWithinSystemInSeconds(
    start,
    end,
    shipSpeed: shipSpeed,
  );
  return RouteAction(
    startSymbol: start.symbol,
    endSymbol: end.symbol,
    type: RouteActionType.navCruise,
    duration: duration,
  );
}

RouteAction _jumpAction(
  SystemsCache systemsCache,
  SystemWaypoint start,
  SystemWaypoint end,
  int shipSpeed, {
  required bool isLastJump,
}) {
  final startSystem = systemsCache.systemBySymbol(start.systemSymbol);
  final endSystem = systemsCache.systemBySymbol(end.systemSymbol);
  final cooldown = cooldownTimeForJumpBetweenSystems(startSystem, endSystem);
  // This isn't quite right to use cooldown as duration, but it's
  // close enough for now.  This isLastJump hack also would break
  // if we had two separate series of jumps in the route.
  final duration = isLastJump ? 0 : cooldown;
  return RouteAction(
    startSymbol: start.symbol,
    endSymbol: end.symbol,
    type: RouteActionType.jump,
    duration: duration,
  );
}

/// A route planner.
// Using a class instead of a function for easier mocking in tests.
class RoutePlanner {
  /// Create a new route planner.
  RoutePlanner({
    required SystemsCache systemsCache,
    required SystemConnectivity systemConnectivity,
    required JumpCache jumpCache,
  })  : _systemsCache = systemsCache,
        _systemConnectivity = systemConnectivity,
        _jumpCache = jumpCache;

  /// Create a new route planner from a systems cache.
  RoutePlanner.fromSystemsCache(SystemsCache systemsCache)
      : this(
          systemsCache: systemsCache,
          systemConnectivity: SystemConnectivity.fromSystemsCache(systemsCache),
          jumpCache: JumpCache(),
        );

  final SystemsCache _systemsCache;
  final SystemConnectivity _systemConnectivity;
  final JumpCache _jumpCache;

  /// Plan a route between two waypoints.
  RoutePlan? planRoute({
    required SystemWaypoint start,
    required SystemWaypoint end,
    required int fuelCapacity,
    required int shipSpeed,
  }) {
    // TODO(eseidel): This is wrong.  An empty route is not valid.
    if (start.symbol == end.symbol) {
      // throw ArgumentError('Cannot plan route between same waypoint');
      return RoutePlan(
        actions: const [],
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
        fuelUsed: 0,
      );
    }

    // We only handle jumps at the moment.
    // We fail out quickly from our reachability cache if these system waypoints
    // are not in the same system cluster.
    if (!_systemConnectivity.canJumpBetweenSystemSymbols(
      start.systemSymbol,
      end.systemSymbol,
    )) {
      return null;
    }

    // Look up in the jump cache, if so, create a plan from that.
    final jumpPlan = _jumpCache.lookupJumpPlan(
      fromSystem: start.systemSymbol,
      toSystem: end.systemSymbol,
    );
    if (jumpPlan != null) {
      return routePlanFromJumpPlan(
        _systemsCache,
        start: start,
        end: end,
        jumpPlan: jumpPlan,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      );
    }

    final startTime = DateTime.timestamp();

    // logger.detail('Planning route from ${start.symbol} to ${end.symbol} '
    // 'fuelCapacity: $fuelCapacity shipSpeed: $shipSpeed');
    final symbols = findWaypointPathJumpsOnly(
      _systemsCache,
      start,
      end,
      shipSpeed,
    );
    if (symbols == null) {
      return null;
    }

    final endTime = DateTime.timestamp();
    final planningDuration = endTime.difference(startTime);
    if (planningDuration.inSeconds > 1) {
      logger.warn('planning ${start.symbol} to ${end.symbol} '
          'took ${approximateDuration(planningDuration)}');
    }

    // walk backwards from end through symbols to build the route
    // we could alternatively build it forward and then fix the jump durations
    // after.
    final route = <RouteAction>[];
    var isLastJump = true;
    for (var i = symbols.length - 1; i > 0; i--) {
      final current = symbols[i];
      final previous = symbols[i - 1];
      final previousWaypoint = _systemsCache.waypointFromSymbol(previous);
      final currentWaypoint = _systemsCache.waypointFromSymbol(current);
      if (previousWaypoint.systemSymbol != currentWaypoint.systemSymbol) {
        // Assume we jumped.
        route.add(
          _jumpAction(
            _systemsCache,
            previousWaypoint,
            currentWaypoint,
            shipSpeed,
            isLastJump: isLastJump,
          ),
        );
        isLastJump = false;
      } else {
        route.add(
          _navigationAction(
            previousWaypoint,
            currentWaypoint,
            shipSpeed,
          ),
        );
      }
    }

    final actions = route.reversed.toList();
    final fuelUsed = _fuelUsedByActions(_systemsCache, actions);

    _saveJumpsInCache(_jumpCache, actions);

    return RoutePlan(
      fuelCapacity: fuelCapacity,
      shipSpeed: shipSpeed,
      actions: actions,
      fuelUsed: fuelUsed,
    );
  }
}

int _fuelUsedByActions(SystemsCache systemsCache, List<RouteAction> actions) {
  var fuelUsed = 0;
  for (final action in actions) {
    if (action.type != RouteActionType.navCruise) {
      continue;
    }
    final start = action.startSymbol;
    final end = action.endSymbol;
    final startWaypoint = systemsCache.waypointFromSymbol(start);
    final endWaypoint = systemsCache.waypointFromSymbol(end);
    fuelUsed += fuelUsedWithinSystem(startWaypoint, endWaypoint);
  }
  return fuelUsed;
}

/// Plan a route through a series of waypoints.
RoutePlan? planRouteThrough(
  SystemsCache systemsCache,
  RoutePlanner routePlanner,
  List<String> waypointSymbols, {
  required int fuelCapacity,
  required int shipSpeed,
}) {
  if (waypointSymbols.length < 2) {
    throw ArgumentError('Must have at least two waypoints');
  }
  final segments = <RoutePlan>[];
  for (var i = 0; i < waypointSymbols.length - 1; i++) {
    final startSymbol = waypointSymbols[i];
    final endSymbol = waypointSymbols[i + 1];
    // Skip any segments where we start and end at the same waypoint.
    // costOutDeal currently calls this with:
    // [shipLocation, start, end] if shipLocation == start, then we can skip.
    if (startSymbol == endSymbol) {
      continue;
    }
    final start = systemsCache.waypointFromSymbol(startSymbol);
    final end = systemsCache.waypointFromSymbol(endSymbol);
    final plan = routePlanner.planRoute(
      start: start,
      end: end,
      fuelCapacity: fuelCapacity,
      shipSpeed: shipSpeed,
    );
    if (plan == null) {
      return null;
    }
    segments.add(plan);
  }
  // Combine segments into a single plan.
  final actions = <RouteAction>[];
  for (final segment in segments) {
    actions.addAll(segment.actions);
  }
  final fuelUsed = _fuelUsedByActions(systemsCache, actions);
  return RoutePlan(
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    actions: actions,
    fuelUsed: fuelUsed,
  );
}

/// Returns a string describing the route plan.
String describeRoutePlan(RoutePlan plan) {
  final buffer = StringBuffer()
    ..writeln('Route ${plan.startSymbol} to ${plan.endSymbol} '
        'speed: ${plan.shipSpeed} max-fuel: ${plan.fuelCapacity}');
  for (final action in plan.actions) {
    buffer.writeln('${action.type.name.padRight(14)}  ${action.startSymbol}  '
        '${action.endSymbol}  '
        '${action.duration}s');
  }
  buffer.writeln('Total duration ${plan.duration}s');
  return buffer.toString();
}
