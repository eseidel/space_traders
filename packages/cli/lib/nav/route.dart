import 'dart:math';

import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/system_pathing.dart';
import 'package:cli/nav/waypoint_pathing.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// The type of travel.
enum TravelMethod {
  /// Traveling using the nav system, only within a system.
  navigate,

  /// Traveling using the warp system, between systems.
  warp,
}

/// Given a start location and a set of waypoint symbols find the approximate
/// round trip distance to visit all symbols and return to the start.
int approximateRoundTripDistanceWithinSystem(
  SystemsCache systemsCache,
  WaypointSymbol startSymbol,
  Set<WaypointSymbol> symbols,
) {
  final start = systemsCache.waypoint(startSymbol);
  final waypoints = symbols
      // ignore start symbol in the symbols list. Could also throw.
      .where((s) => s != startSymbol)
      .map((s) => systemsCache.waypoint(s))
      .toList();
  if (waypoints.any((w) => w.system != start.system)) {
    throw ArgumentError('All waypoints must be in the same system.');
  }
  var distance = 0.0;
  var current = start;
  while (waypoints.isNotEmpty) {
    final next = minBy(waypoints, (w) => w.distanceTo(current))!;
    distance += current.distanceTo(next);
    waypoints.remove(next);
    current = next;
  }
  distance += current.distanceTo(start);
  return distance.ceil();
}

// https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
/// Returns the fuel used for with a flight mode and the given distance.
int fuelUsedByDistance(
  double distance,
  ShipNavFlightMode flightMode,
) {
  final intDistance = distance.ceil();
  switch (flightMode) {
    case ShipNavFlightMode.DRIFT:
      return 1;
    case ShipNavFlightMode.STEALTH:
      return intDistance;
    case ShipNavFlightMode.CRUISE:
      return intDistance;
    case ShipNavFlightMode.BURN:
      return 2 * intDistance;
  }
  // This is only needed because ShipNavFlightMode is not an enum.
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

Map<ShipNavFlightMode, int> _navSpeedMultiplier = {
  ShipNavFlightMode.CRUISE: 25,
  ShipNavFlightMode.DRIFT: 250,
};
Map<ShipNavFlightMode, int> _warpSpeedMultiplier = {
  ShipNavFlightMode.CRUISE: 50,
  ShipNavFlightMode.DRIFT: 300,
};

double _speedMultiplier(ShipNavFlightMode flightMode, TravelMethod travelType) {
  final map = travelType == TravelMethod.navigate
      ? _navSpeedMultiplier
      : _warpSpeedMultiplier;
  final multiplier = map[flightMode];
  if (multiplier == null) {
    throw UnimplementedError('Unimplmented $flightMode for $travelType');
  }
  return multiplier.toDouble();
}

// https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
/// Returns the flight time to the given distance.
int flightTimeByDistanceAndSpeed({
  required double distance,
  required int shipSpeed,
  required ShipNavFlightMode flightMode,
}) {
  final double roundedDistance = max(1, distance.roundToDouble());

  /// Wiki says round(), but that doesn't match observed behavior with probes.
  final multiplier = _speedMultiplier(flightMode, TravelMethod.navigate);
  return (roundedDistance * (multiplier / shipSpeed) + 15).floor();
}

/// Returns the warp time to the given distance.
int warpTimeByDistanceAndSpeed({
  required double distance,
  required int shipSpeed,
  required ShipNavFlightMode flightMode,
}) {
  final double roundedDistance = max(1, distance.roundToDouble());
  return (roundedDistance *
              (_speedMultiplier(flightMode, TravelMethod.warp) / shipSpeed) +
          15)
      .floor();
}

/// Returns the flight time to the given waypoint.
int flightTimeWithinSystemInSeconds(
  SystemWaypoint a,
  SystemWaypoint b, {
  required int shipSpeed,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final distance = a.distanceTo(b);
  return flightTimeByDistanceAndSpeed(
    distance: distance,
    shipSpeed: shipSpeed,
    flightMode: flightMode,
  );
}

/// Returns the warp time to the given waypoint.
int warpTimeInSeconds(
  System a,
  System b, {
  required int shipSpeed,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final distance = a.distanceTo(b);
  return warpTimeByDistanceAndSpeed(
    distance: distance,
    shipSpeed: shipSpeed,
    flightMode: flightMode,
  );
}

/// Returns the cooldown time after jumping a given distance.
int cooldownTimeForJumpDistance(int distance) {
  if (distance < 0) {
    throw ArgumentError('Distance $distance is negative.');
  }
  // There is no longer a limit on jump distance, just a question
  // of if two systems are connected by a jumpgate.
  return distance + 60;
}

/// Returns the cooldown time after jumping between two systems.
int cooldownTimeForJumpBetweenSystems(System a, System b) {
  if (a.symbol == b.symbol) {
    throw ArgumentError('Cannot jump to the same system ${a.symbol}.');
  }
  // There is no longer a limit on jump distance, just a question
  // of if two systems are connected by a jumpgate.
  // This would need to check that this two are connected by a jumpgate.
  return cooldownTimeForJumpDistance(a.distanceTo(b).round());
}

/// Logic for modifying RoutePlans
extension RoutePlanPlanning on RoutePlan {
  /// Makes a new route plan starting from the given waypoint.
  RoutePlan subPlanStartingFrom(WaypointSymbol waypointSymbol) {
    final index = actions.indexWhere((e) => e.startSymbol == waypointSymbol);
    // This most commonly occurs when something asks for the endSymbol.
    if (index == -1) {
      throw ArgumentError('No action starting from $waypointSymbol');
    }
    final newActions = actions.sublist(index);
    return RoutePlan(
      fuelCapacity: fuelCapacity,
      shipSpeed: shipSpeed,
      actions: newActions,
    );
  }
}

/// Plan a route between two waypoints using a pre-computed jump plan.
RoutePlan routePlanFromJumpPlan(
  SystemsCache systemsCache,
  JumpPlan jumpPlan,
  ShipSpec shipSpec, {
  required WaypointSymbol start,
  required WaypointSymbol end,
  required bool Function(WaypointSymbol) sellsFuel,
}) {
  final actions = <RouteAction>[];
  if (jumpPlan.route.first != start.system) {
    throw ArgumentError('Jump plan does not start at ${start.system}');
  }
  if (jumpPlan.route.last != end.system) {
    throw ArgumentError('Jump plan does not end at ${end.system}');
  }
  final startWaypoint = systemsCache.waypoint(start);
  final startJumpGate = systemsCache.jumpGateWaypointForSystem(start.system)!;
  if (startJumpGate.symbol != start) {
    _addSubPlanWithinSystem(
      systemsCache,
      actions,
      startWaypoint,
      startJumpGate,
      shipSpec,
      sellsFuel: sellsFuel,
    );
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
        isLastJump: isLastJump,
      ),
    );
  }
  final endWaypoint = systemsCache.waypoint(end);
  final endJumpGate = systemsCache.jumpGateWaypointForSystem(end.system)!;
  if (endJumpGate.symbol != end) {
    _addSubPlanWithinSystem(
      systemsCache,
      actions,
      endJumpGate,
      endWaypoint,
      shipSpec,
      sellsFuel: sellsFuel,
    );
  }

  return RoutePlan(
    fuelCapacity: shipSpec.fuelCapacity,
    shipSpeed: shipSpec.speed,
    actions: actions,
  );
}

class _JumpPlanBuilder {
  _JumpPlanBuilder();

  final List<SystemSymbol> _systems = [];

  bool get isNotEmpty => _systems.isNotEmpty;

  void addWaypoint(WaypointSymbol waypointSymbol) {
    _systems.add(waypointSymbol.system);
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

void _addSubPlanWithinSystem(
  SystemsCache systemsCache,
  List<RouteAction> route,
  SystemWaypoint start,
  SystemWaypoint end,
  ShipSpec shipSpec, {
  required bool Function(WaypointSymbol) sellsFuel,
}) {
  final actions = findRouteWithinSystem(
    systemsCache,
    shipSpec,
    start: start.symbol,
    end: end.symbol,
    sellsFuel: sellsFuel,
  );
  // This should not be possible.
  if (actions == null) {
    throw ArgumentError('Cannot find route within system from '
        '${start.symbol} to ${end.symbol}');
  }
  route.addAll(actions);
}

RouteAction _jumpAction(
  SystemsCache systemsCache,
  SystemWaypoint start,
  SystemWaypoint end, {
  required bool isLastJump,
}) {
  final startSystem = systemsCache[start.system];
  final endSystem = systemsCache[end.system];
  final cooldown = cooldownTimeForJumpBetweenSystems(startSystem, endSystem);
  // This isn't quite right to use cooldown as duration, but it's
  // close enough for now.  This isLastJump hack also would break
  // if we had two separate series of jumps in the route.
  final seconds = isLastJump ? 0 : cooldown;
  return RouteAction(
    startSymbol: start.symbol,
    endSymbol: end.symbol,
    type: RouteActionType.jump,
    seconds: seconds,
    fuelUsed: 0,
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
    required bool Function(WaypointSymbol) sellsFuel,
  })  : _systemsCache = systemsCache,
        _sellsFuel = sellsFuel,
        _systemConnectivity = systemConnectivity,
        _jumpCache = jumpCache;

  /// Create a new route planner from a systems cache.
  RoutePlanner.fromSystemsCache(
    SystemsCache systemsCache,
    SystemConnectivity systemConnectivity, {
    required bool Function(WaypointSymbol) sellsFuel,
  }) : this(
          systemsCache: systemsCache,
          systemConnectivity: systemConnectivity,
          jumpCache: JumpCache(),
          sellsFuel: sellsFuel,
        );

  // SystemsCache knows all the systems and where they are.
  final SystemsCache _systemsCache;
  // SystemConnectivity and JumpCache are related perf optimizations.
  // SystemConnectivity is used to quickly reject routes between systems
  // that are not connected.
  final SystemConnectivity _systemConnectivity;
  // JumpCache is used to cache specific jump sequences between systems.
  final JumpCache _jumpCache;
  final bool Function(WaypointSymbol) _sellsFuel;

  // TODO(eseidel): This shouldn't be public.
  /// The connectivity used for this RoutePlanner.
  SystemConnectivity get systemConnectivity => _systemConnectivity;

  /// Clear any cached routing data.  Called when jump gate availability changes
  /// because a jump gate is constructed.
  void clearRoutingCaches() {
    _jumpCache.clear();
  }

  RoutePlan? _planJump(
    ShipSpec shipSpec, {
    required WaypointSymbol start,
    required WaypointSymbol end,
  }) {
    if (start.system == end.system) {
      throw ArgumentError('Cannot plan a jump within the same system.');
    }
    // We only handle jumps at the moment.
    // We fail out quickly from our reachability cache if these system waypoints
    // are not in the same system cluster.
    if (!_systemConnectivity.existsJumpPathBetween(
      start.system,
      end.system,
    )) {
      return null;
    }

    // Look up in the jump cache, if so, create a plan from that.
    final jumpPlan = _jumpCache.lookupJumpPlan(
      fromSystem: start.system,
      toSystem: end.system,
    );
    if (jumpPlan != null) {
      return routePlanFromJumpPlan(
        _systemsCache,
        jumpPlan,
        shipSpec,
        start: start,
        end: end,
        sellsFuel: _sellsFuel,
      );
    }

    final startTime = DateTime.timestamp();

    // logger.detail('Planning route from ${start.symbol} to ${end.symbol} '
    // 'fuelCapacity: $fuelCapacity shipSpeed: $shipSpeed');
    final symbols = findWaypointPathJumpsOnly(
      _systemsCache,
      _systemConnectivity,
      start,
      end,
    );
    if (symbols == null) {
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
    final route = <RouteAction>[];
    var isLastJump = true;
    for (var i = symbols.length - 1; i > 0; i--) {
      final current = symbols[i];
      final previous = symbols[i - 1];
      final previousWaypoint = _systemsCache.waypoint(previous);
      final currentWaypoint = _systemsCache.waypoint(current);
      if (previousWaypoint.system != currentWaypoint.system) {
        // Assume we jumped.
        route.add(
          _jumpAction(
            _systemsCache,
            previousWaypoint,
            currentWaypoint,
            isLastJump: isLastJump,
          ),
        );
        isLastJump = false;
      } else {
        _addSubPlanWithinSystem(
          _systemsCache,
          route,
          previousWaypoint,
          currentWaypoint,
          shipSpec,
          sellsFuel: _sellsFuel,
        );
      }
    }

    final actions = route.reversed.toList();

    _saveJumpsInCache(_jumpCache, actions);

    return RoutePlan(
      fuelCapacity: shipSpec.fuelCapacity,
      shipSpeed: shipSpec.speed,
      actions: actions,
    );
  }

  RoutePlan? _planWithinSystem(
    ShipSpec shipSpec, {
    required WaypointSymbol start,
    required WaypointSymbol end,
  }) {
    if (start.system != end.system) {
      return null;
    }

    final startTime = DateTime.timestamp();
    final actions = findRouteWithinSystem(
      _systemsCache,
      shipSpec,
      start: start,
      end: end,
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
    return RoutePlan(
      fuelCapacity: shipSpec.fuelCapacity,
      shipSpeed: shipSpec.speed,
      actions: actions,
    );
  }

  /// Plan a route between two waypoints.
  RoutePlan? planRoute(
    ShipSpec shipSpec, {
    required WaypointSymbol start,
    required WaypointSymbol end,
  }) {
    // TODO(eseidel): This is wrong.  An empty route is not valid.
    if (start.waypoint == end.waypoint) {
      // throw ArgumentError('Cannot plan route between same waypoint');
      return RoutePlan.empty(
        symbol: start,
        fuelCapacity: shipSpec.fuelCapacity,
        shipSpeed: shipSpec.speed,
      );
    }

    if (start.system == end.system) {
      // plan a route within a system
      return _planWithinSystem(
        shipSpec,
        start: start,
        end: end,
      );
    }
    // plan a route between systems
    return _planJump(
      shipSpec,
      start: start,
      end: end,
    );
  }
}

/// Plan a route through a series of waypoints.
RoutePlan? planRouteThrough(
  SystemsCache systemsCache,
  RoutePlanner routePlanner,
  ShipSpec shipSpec,
  List<WaypointSymbol> waypointSymbols,
) {
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
      shipSpec,
      start: start,
      end: end,
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
  return RoutePlan(
    fuelCapacity: shipSpec.fuelCapacity,
    shipSpeed: shipSpec.speed,
    actions: actions,
  );
}

/// Returns a string describing the route plan.
String describeRoutePlan(RoutePlan plan) {
  final buffer = StringBuffer()
    ..writeln('${plan.startSymbol} to ${plan.endSymbol} '
        'speed: ${plan.shipSpeed} max-fuel: ${plan.fuelCapacity}');
  for (final action in plan.actions) {
    buffer.writeln('${action.type.name.padRight(14)}  ${action.startSymbol}  '
        '${action.endSymbol} ${approximateDuration(action.duration)}'
        ' ${action.fuelUsed} fuel');
  }
  buffer.writeln(
    'in ${plan.duration} uses ${plan.fuelUsed} fuel',
  );
  return buffer.toString();
}

/// Compute the nearest shipyard to the given start.
Future<ShipyardListing?> nearestShipyard(
  RoutePlanner routePlanner,
  ShipyardListingSnapshot shipyards,
  WaypointSymbol start,
) async {
  final listings = shipyards.listingsInSystem(start.system);

  // If not in this system.  Should list all shipyardListings.
  // Filter by ones which are reachable (e.g. if this ship can warp).
  // Pick the one with the shortest route.

  // TODO(eseidel): Sort by distance.
  // TODO(eseidel): Consider reachable systems not just this one.
  return listings.firstOrNull;
}
