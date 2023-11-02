import 'dart:math';

import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/waypoint_pathing.dart';
import 'package:cli/printing.dart';
import 'package:types/types.dart';

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
  final double roundedDistance = max(1, distance.roundToDouble());

  /// Wiki says round(), but that doesn't match observed behavior with probes.
  return (roundedDistance * (_speedMultiplier(flightMode) / shipSpeed) + 15)
      .floor();
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
  if (distance > kJumpGateRange) {
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
  if (distance > kJumpGateRange) {
    throw ArgumentError(
      'Distance ${a.symbol} to ${b.symbol} is too far $distance to jump.',
    );
  }
  // This would need to check that this two are connected by a jumpgate.
  return max(60, (distance / 10).round());
}

/// Logic for modifying RoutePlans
extension RoutePlanPlanning on RoutePlan {
  /// Makes a new route plan starting from the given waypoint.
  RoutePlan subPlanStartingFrom(
    SystemsCache systemsCache,
    WaypointSymbol waypointSymbol,
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
}

/// Plan a route between two waypoints using a pre-computed jump plan.
RoutePlan routePlanFromJumpPlan(
  SystemsCache systemsCache, {
  required WaypointSymbol start,
  required WaypointSymbol end,
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
  final startWaypoint = systemsCache.waypointFromSymbol(start);
  final startJumpGate =
      systemsCache.jumpGateWaypointForSystem(start.systemSymbol)!;
  if (startJumpGate.symbol != start.waypoint) {
    actions.add(_navigationAction(startWaypoint, startJumpGate, shipSpeed));
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
  final endWaypoint = systemsCache.waypointFromSymbol(end);
  final endJumpGate = systemsCache.jumpGateWaypointForSystem(end.systemSymbol)!;
  if (endJumpGate.symbol != end.waypoint) {
    actions.add(_navigationAction(endJumpGate, endWaypoint, shipSpeed));
  }

  final fuelUsed = _fuelUsedByActions(systemsCache, actions);
  return RoutePlan(
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    actions: actions,
    fuelUsed: fuelUsed,
  );
}

// class _JumpPlanBuilder {
//   _JumpPlanBuilder();

//   final List<SystemSymbol> _systems = [];

//   bool get isNotEmpty => _systems.isNotEmpty;

//   void addWaypoint(WaypointSymbol waypointSymbol) {
//     _systems.add(waypointSymbol.systemSymbol);
//   }

//   JumpPlan build() {
//     final plan = JumpPlan(_systems);
//     _systems.clear();
//     return plan;
//   }
// }

// void _saveJumpsInCache(JumpCache jumpCache, List<RouteAction> actions) {
//   // Walk through actions, find any jump sequences, turn those into JumpPlans
//   // which are then given to the JumpCache.
//   final builder = _JumpPlanBuilder();
//   for (var i = 0; i < actions.length; i++) {
//     final action = actions[i];
//     if (action.type == RouteActionType.jump) {
//       builder.addWaypoint(action.startSymbol);
//     } else {
//       if (builder.isNotEmpty) {
//         builder.addWaypoint(action.startSymbol);
//         jumpCache.addJumpPlan(builder.build());
//       }
//     }
//   }
//   // This only happens when the last action is a jump e.g. we're at a jumpgate.
//   if (builder.isNotEmpty) {
//     builder.addWaypoint(actions.last.endSymbol);
//     jumpCache.addJumpPlan(builder.build());
//   }
// }

RouteAction _navigationAction(
  SystemWaypoint start,
  SystemWaypoint end,
  int shipSpeed,
) {
  final seconds = flightTimeWithinSystemInSeconds(
    start,
    end,
    shipSpeed: shipSpeed,
  );
  return RouteAction(
    startSymbol: start.waypointSymbol,
    endSymbol: end.waypointSymbol,
    type: RouteActionType.navCruise,
    seconds: seconds,
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
  final seconds = isLastJump ? 0 : cooldown;
  return RouteAction(
    startSymbol: start.waypointSymbol,
    endSymbol: end.waypointSymbol,
    type: RouteActionType.jump,
    seconds: seconds,
  );
}

/// A route planner.
// Using a class instead of a function for easier mocking in tests.
class RoutePlanner {
  /// Create a new route planner.
  RoutePlanner({
    required SystemsCache systemsCache,
    // required SystemConnectivity systemConnectivity,
    // required JumpCache jumpCache,
    required bool Function(WaypointSymbol) sellsFuel,
  })  : _systemsCache = systemsCache,
        _sellsFuel = sellsFuel;
  // _systemConnectivity = systemConnectivity,
  // _jumpCache = jumpCache

  /// Create a new route planner from a systems cache.
  RoutePlanner.fromSystemsCache(
    SystemsCache systemsCache, {
    required bool Function(WaypointSymbol) sellsFuel,
  }) : this(
          systemsCache: systemsCache,
          // systemConnectivity: SystemConnectivity
          //    .fromSystemsCache(systemsCache),
          // jumpCache: JumpCache(),
          sellsFuel: sellsFuel,
        );

  final SystemsCache _systemsCache;
  // final SystemConnectivity _systemConnectivity;
  // final JumpCache _jumpCache;
  final bool Function(WaypointSymbol) _sellsFuel;

  RoutePlan? _planJump({
    required WaypointSymbol start,
    required WaypointSymbol end,
    required int fuelCapacity,
    required int shipSpeed,
  }) {
    // We only handle jumps at the moment.
    // We fail out quickly from our reachability cache if these system waypoints
    // are not in the same system cluster.
    // if (!_systemConnectivity.canJumpBetweenSystemSymbols(
    //   start.systemSymbol,
    //   end.systemSymbol,
    // )) {
    //   return null;
    // }

    // Look up in the jump cache, if so, create a plan from that.
    // final jumpPlan = _jumpCache.lookupJumpPlan(
    //   fromSystem: start.systemSymbol,
    //   toSystem: end.systemSymbol,
    // );
    // if (jumpPlan != null) {
    //   return routePlanFromJumpPlan(
    //     _systemsCache,
    //     start: start,
    //     end: end,
    //     jumpPlan: jumpPlan,
    //     fuelCapacity: fuelCapacity,
    //     shipSpeed: shipSpeed,
    //   );
    // }

    // final startTime = DateTime.timestamp();

    // // logger.detail('Planning route from ${start.symbol} to ${end.symbol} '
    // // 'fuelCapacity: $fuelCapacity shipSpeed: $shipSpeed');
    // final symbols = findWaypointPathJumpsOnly(
    //   _systemsCache,
    //   start,
    //   end,
    //   shipSpeed,
    // );
    // if (symbols == null) {
    //   return null;
    // }

    // final endTime = DateTime.timestamp();
    // final planningDuration = endTime.difference(startTime);
    // if (planningDuration.inSeconds > 1) {
    //   logger.warn('planning $start to $end '
    //       'took ${approximateDuration(planningDuration)}');
    // }

    // // walk backwards from end through symbols to build the route
    // // we could alternatively build it forward and then fix the jump durations
    // // after.
    // final route = <RouteAction>[];
    // var isLastJump = true;
    // for (var i = symbols.length - 1; i > 0; i--) {
    //   final current = symbols[i];
    //   final previous = symbols[i - 1];
    //   final previousWaypoint = _systemsCache.waypointFromSymbol(previous);
    //   final currentWaypoint = _systemsCache.waypointFromSymbol(current);
    //   if (previousWaypoint.systemSymbol != currentWaypoint.systemSymbol) {
    //     // Assume we jumped.
    //     route.add(
    //       _jumpAction(
    //         _systemsCache,
    //         previousWaypoint,
    //         currentWaypoint,
    //         shipSpeed,
    //         isLastJump: isLastJump,
    //       ),
    //     );
    //     isLastJump = false;
    //   } else {
    //     route.add(
    //       _navigationAction(
    //         previousWaypoint,
    //         currentWaypoint,
    //         shipSpeed,
    //       ),
    //     );
    //   }
    // }

    // final actions = route.reversed.toList();
    // final fuelUsed = _fuelUsedByActions(_systemsCache, actions);

    // _saveJumpsInCache(_jumpCache, actions);

    // return RoutePlan(
    //   fuelCapacity: fuelCapacity,
    //   shipSpeed: shipSpeed,
    //   actions: actions,
    //   fuelUsed: fuelUsed,
    // );

    return null;
  }

  RoutePlan? _planWithinSystem({
    required WaypointSymbol start,
    required WaypointSymbol end,
    required int fuelCapacity,
    required int shipSpeed,
  }) {
    if (start.systemSymbol != end.systemSymbol) {
      return null;
    }

    final startTime = DateTime.timestamp();
    final actions = findWaypointPathWithinSystem(
      _systemsCache,
      start: start,
      end: end,
      shipSpeed: shipSpeed,
      fuelCapacity: fuelCapacity,
      sellsFuel: _sellsFuel,
    );
    if (actions == null) {
      return null;
    }

    final endTime = DateTime.timestamp();
    final planningDuration = endTime.difference(startTime);
    if (planningDuration.inSeconds > 1) {
      logger.warn('planning $start to $end '
          'took ${approximateDuration(planningDuration)}');
    }

    // walk backwards from end through symbols to build the route
    // we could alternatively build it forward and then fix the jump durations
    // after.
    final fuelUsed = _fuelUsedByActions(_systemsCache, actions);
    return RoutePlan(
      fuelCapacity: fuelCapacity,
      shipSpeed: shipSpeed,
      actions: actions,
      fuelUsed: fuelUsed,
    );
  }

  /// Plan a route between two waypoints.
  RoutePlan? planRoute({
    required WaypointSymbol start,
    required WaypointSymbol end,
    required int fuelCapacity,
    required int shipSpeed,
  }) {
    // TODO(eseidel): This is wrong.  An empty route is not valid.
    if (start.waypoint == end.waypoint) {
      // throw ArgumentError('Cannot plan route between same waypoint');
      return RoutePlan.empty(
        symbol: start,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      );
    }

    if (start.systemSymbol == end.systemSymbol) {
      // plan a route within a system
      return _planWithinSystem(
        start: start,
        end: end,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      );
    }
    // plan a route between systems
    return _planJump(
      start: start,
      end: end,
      fuelCapacity: fuelCapacity,
      shipSpeed: shipSpeed,
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
  List<WaypointSymbol> waypointSymbols, {
  required int fuelCapacity,
  required int shipSpeed,
}) {
  if (waypointSymbols.length < 2) {
    throw ArgumentError('Must have at least two waypoints');
  }
  final segments = <RoutePlan>[];
  for (var i = 0; i < waypointSymbols.length - 1; i++) {
    final start = waypointSymbols[i];
    final end = waypointSymbols[i + 1];
    // Skip any segments where we start and end at the same waypoint.
    // costOutDeal currently calls this with:
    // [shipLocation, start, end] if shipLocation == start, then we can skip.
    if (start == end) {
      continue;
    }
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
    ..writeln('${plan.startSymbol} to ${plan.endSymbol} '
        'speed: ${plan.shipSpeed} max-fuel: ${plan.fuelCapacity}');
  for (final action in plan.actions) {
    buffer.writeln('${action.type.name.padRight(14)}  ${action.startSymbol}  '
        '${action.endSymbol}  '
        '${action.duration}s');
  }
  buffer.writeln('in ${approximateDuration(plan.duration)}');
  return buffer.toString();
}
