import 'dart:math';

import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
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

typedef _WaypointSymbol = String;

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

Iterable<_WaypointSymbol> _neighborsFor(
  SystemsCache systemsCache,
  _WaypointSymbol symbol,
) sync* {
  final waypoint = systemsCache.waypointFromSymbol(symbol);
  // If we're currently at a jump gate, we can jump to any other jumpgate
  // connected to this one.
  if (waypoint.isJumpGate) {
    final systems = systemsCache.connectedSystems(waypoint.systemSymbol);
    for (final system in systems) {
      yield systemsCache.jumpGateWaypointForSystem(system.symbol)!.symbol;
    }
  }
  // Otherwise we can always navigate to any other waypoint in this system.
  // TODO(eseidel): This needs to enforce fuelCapacity.
  final otherWaypoints = systemsCache.waypointsInSystem(waypoint.systemSymbol);
  for (final otherWaypoint in otherWaypoints) {
    if (otherWaypoint.symbol != waypoint.symbol) {
      yield otherWaypoint.symbol;
    }
  }
  // We don't currently support warping.
}

int _approximateTimeBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  _WaypointSymbol bSymbol,
  int shipSpeed,
) {
  if (a.symbol == bSymbol) {
    return 0;
  }
  final b = systemsCache.waypointFromSymbol(bSymbol);
  if (a.systemSymbol == b.systemSymbol) {
    return flightTimeWithinSystemInSeconds(a, b, shipSpeed: shipSpeed);
    // return a.position.distanceTo(b.position) ~/ shipSpeed;
  }
  final aSystem = systemsCache.systemBySymbol(a.systemSymbol);
  final aGate = aSystem.jumpGateWaypoint;
  if (aGate == null) {
    throw Exception('No jump gate in system ${a.systemSymbol}');
  }
  final bSystem = systemsCache.systemBySymbol(b.systemSymbol);
  final bGate = bSystem.jumpGateWaypoint;
  if (bGate == null) {
    throw Exception('No jump gate in system ${b.systemSymbol}');
  }
  final systemDistance = aSystem.distanceTo(bSystem);
  // final aTimeToGate = a.distanceTo(aGate) ~/ shipSpeed;
  // final bTimeToGate = b.distanceTo(bGate) ~/ shipSpeed;
  final aTimeToGate =
      flightTimeWithinSystemInSeconds(a, aGate, shipSpeed: shipSpeed);
  final bTimeToGate =
      flightTimeWithinSystemInSeconds(b, bGate, shipSpeed: shipSpeed);
  // Cooldown time for jumps is Math.max(60, distance / 10)
  // distance / 10 is an approximation of the cooldown time for a jump gate.
  // This assumes there are direct jumps in a line.
  return aTimeToGate + bTimeToGate + systemDistance ~/ 10;
}

int _timeBetween(
  SystemsCache systemsCache,
  _WaypointSymbol aSymbol,
  _WaypointSymbol bSymbol,
  int shipSpeed,
) {
  if (aSymbol == bSymbol) {
    return 0;
  }
  // TODO(eseidel): This should compute the exact travel time and likely
  // return a RouteAction.
  final a = systemsCache.waypointFromSymbol(aSymbol);
  final b = systemsCache.waypointFromSymbol(bSymbol);
  return _approximateTimeBetween(systemsCache, a, b.symbol, shipSpeed);
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

/// Plan a route between two waypoints.
RoutePlan? planRoute(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  JumpCache jumpCache, {
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
  if (!systemConnectivity.canJumpBetween(
    startSystemSymbol: start.systemSymbol,
    endSystemSymbol: end.systemSymbol,
  )) {
    return null;
  }

  // Look up in the jump cache, if so, create a plan from that.
  final jumpPlan = jumpCache.lookupJumpPlan(
    fromSystem: start.systemSymbol,
    toSystem: end.systemSymbol,
  );
  if (jumpPlan != null) {
    return routePlanFromJumpPlan(
      systemsCache,
      start: start,
      end: end,
      jumpPlan: jumpPlan,
      fuelCapacity: fuelCapacity,
      shipSpeed: shipSpeed,
    );
  }

  // logger.detail('Planning route from ${start.symbol} to ${end.symbol} '
  // 'fuelCapacity: $fuelCapacity shipSpeed: $shipSpeed');

  // This is A* search, thanks to
  // https://www.redblobgames.com/pathfinding/a-star/introduction.html
  final frontier =
      PriorityQueue<(_WaypointSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((start.symbol, 0));
  final cameFrom = <_WaypointSymbol, _WaypointSymbol>{};
  final costSoFar = <_WaypointSymbol, int>{};
  // logger.info('start: ${start.symbol} end: ${end.symbol}');
  costSoFar[start.symbol] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    // logger.info('current: ${current.$1}');
    if (current.$1 == end.symbol) {
      break;
    }
    for (final next in _neighborsFor(systemsCache, current.$1)) {
      // logger.info('considering: $next');
      final newCost = costSoFar[current.$1]! +
          _timeBetween(systemsCache, current.$1, next, shipSpeed);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost +
            _approximateTimeBetween(systemsCache, end, next, shipSpeed);
        frontier.add((next, priority));
        cameFrom[next] = current.$1;
      }
    }
  }
  if (cameFrom[end.symbol] == null) {
    return null;
  }

  // walk backwards from end through cameFrom to build the route
  final route = <RouteAction>[];
  var current = end.symbol;
  var isLastJump = true;
  while (current != start.symbol) {
    final previous = cameFrom[current]!;
    final previousWaypoint = systemsCache.waypointFromSymbol(previous);
    final currentWaypoint = systemsCache.waypointFromSymbol(current);
    if (previousWaypoint.systemSymbol != currentWaypoint.systemSymbol) {
      // Assume we jumped.
      route.add(
        _jumpAction(
          systemsCache,
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

    current = previous;
  }

  final actions = route.reversed.toList();
  final fuelUsed = _fuelUsedByActions(systemsCache, actions);

  _saveJumpsInCache(jumpCache, actions);

  return RoutePlan(
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    actions: actions,
    fuelUsed: fuelUsed,
  );
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
  SystemConnectivity systemConnectivity,
  JumpCache jumpCache,
  List<String> waypointSymbols, {
  required int fuelCapacity,
  required int shipSpeed,
}) {
  if (waypointSymbols.length < 2) {
    throw ArgumentError('Must have at least two waypoints');
  }
  final segments = <RoutePlan>[];
  for (var i = 0; i < waypointSymbols.length - 1; i++) {
    final start = systemsCache.waypointFromSymbol(waypointSymbols[i]);
    final end = systemsCache.waypointFromSymbol(waypointSymbols[i + 1]);
    final plan = planRoute(
      systemsCache,
      systemConnectivity,
      jumpCache,
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
