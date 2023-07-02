import 'dart:math';

import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Returns the fuel cost to the given waypoint.
int fuelUsedWithinSystem(
  SystemWaypoint a,
  SystemWaypoint b, {
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final distance = a.distanceTo(b);
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

/// Returns the flight time to the given waypoint.
int flightTimeWithinSystemInSeconds(
  SystemWaypoint a,
  SystemWaypoint b, {
  required int shipSpeed,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  // https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
  final distance = a.distanceTo(b);
  final distanceBySpeed = distance ~/ shipSpeed;

  switch (flightMode) {
    case ShipNavFlightMode.DRIFT:
      return 15 + 100 * distanceBySpeed;
    case ShipNavFlightMode.STEALTH:
      return 15 + 20 * distanceBySpeed;
    case ShipNavFlightMode.CRUISE:
      return 15 + 10 * distanceBySpeed;
    case ShipNavFlightMode.BURN:
      return 15 + 5 * distanceBySpeed;
  }
  throw UnimplementedError('Unknown flight mode: $flightMode');
}

/// Returns the fuel cost to travel between two waypoints.
/// This assumes the two waypoints are either within the same system
/// or are connected by jump gates.
int fuelUsedBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  SystemWaypoint b,
) {
  if (a.systemSymbol == b.systemSymbol) {
    return fuelUsedWithinSystem(a, b);
  }
  // a -> jump gate
  // jump N times
// jump gate -> b
  final aJumpGate = systemsCache.jumpGateWaypointForSystem(a.systemSymbol);
  if (aJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${a.systemSymbol}',
    );
  }
  // Ignoring if there is actually a path between the jump gates.
  final bJumpGate = systemsCache.jumpGateWaypointForSystem(b.systemSymbol);
  if (bJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${b.systemSymbol}',
    );
  }
  return fuelUsedWithinSystem(a, aJumpGate) +
      fuelUsedWithinSystem(bJumpGate, b);
}

/// Returns the cooldown time after jumping between two systems.
int cooldownTimeForJumpBetweenSystems(System a, System b) {
  // This would need to check that this two are connected by a jumpgate.
  final distance = a.distanceTo(b);
  if (distance > 2000) {
    throw ArgumentError(
      'Distance ${a.symbol} to ${b.symbol} is too far $distance to jump.',
    );
  }
  return min(60, distance ~/ 10);
}

/// Returns flight time in seconds between two waypoints.
int flightTimeBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  SystemWaypoint b, {
  required ShipNavFlightMode flightMode,
  required int shipSpeed,
}) {
  if (a.systemSymbol == b.systemSymbol) {
    return flightTimeWithinSystemInSeconds(
      a,
      b,
      flightMode: flightMode,
      shipSpeed: shipSpeed,
    );
  }
  // a -> jump gate
  // jump N times
  // jump gate -> b
  final aJumpGate = systemsCache.jumpGateWaypointForSystem(a.systemSymbol);
  if (aJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${a.systemSymbol}',
    );
  }
  // Ignoring if there is actually a path between the jump gates.
  final bJumpGate = systemsCache.jumpGateWaypointForSystem(b.systemSymbol);
  if (bJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${b.systemSymbol}',
    );
  }
  // Assuming a and b are connected systems!
  return flightTimeWithinSystemInSeconds(
        a,
        aJumpGate,
        flightMode: flightMode,
        shipSpeed: shipSpeed,
      ) +
      flightTimeWithinSystemInSeconds(
        bJumpGate,
        b,
        flightMode: flightMode,
        shipSpeed: shipSpeed,
      );
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

  /// The symbol of the waypoint where this action starts.
  final String startSymbol;

  /// The symbol of the waypoint where this action ends.
  final String endSymbol;

  /// The type of action taken.
  final RouteActionType type;

  /// The duration of this action in seconds.
  final int duration;
  // final int cooldown;
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
  });

  /// The fuel capacity the route was planned for.
  final int fuelCapacity;

  /// The speed of the ship the route was planned for.
  final int shipSpeed;

  /// The actions to take to travel between the two waypoints.
  final List<RouteAction> actions;

  /// The symbol of the waypoint where this route starts.
  String get startSymbol => actions.first.startSymbol;

  /// The symbol of the waypoint where this route ends.
  String get endSymbol => actions.last.endSymbol;

  /// The total time of this route in seconds.
  int get duration => actions.fold<int>(0, (a, b) => a + b.duration);
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
  // Cooldown time for jumps is Math.min(60, distance / 10)
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

/// Plan a route between two waypoints.
RoutePlan? planRoute(
  SystemsCache systemsCache, {
  required SystemWaypoint start,
  required SystemWaypoint end,
  required int fuelCapacity,
  required int shipSpeed,
}) {
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
      final previousSystem =
          systemsCache.systemBySymbol(previousWaypoint.systemSymbol);
      final currentSystem =
          systemsCache.systemBySymbol(currentWaypoint.systemSymbol);
      final cooldown =
          cooldownTimeForJumpBetweenSystems(previousSystem, currentSystem);
      // This isn't quite right to use cooldown as duration, but it's
      // close enough for now.  This isLastJump hack also would break
      // if we had two separate series of jumps in the route.
      final duration = isLastJump ? 0 : cooldown;
      isLastJump = false;
      route.add(
        RouteAction(
          startSymbol: previous,
          endSymbol: current,
          type: RouteActionType.jump,
          duration: duration,
        ),
      );
    } else {
      final duration = flightTimeWithinSystemInSeconds(
        previousWaypoint,
        currentWaypoint,
        shipSpeed: shipSpeed,
      );
      route.add(
        RouteAction(
          startSymbol: previous,
          endSymbol: current,
          type: RouteActionType.navCruise,
          duration: duration,
        ),
      );
    }

    current = previous;
  }

  return RoutePlan(
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    actions: route.reversed.toList(),
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
