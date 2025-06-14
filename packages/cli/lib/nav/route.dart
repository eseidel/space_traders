import 'dart:math';

import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
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
  SystemsSnapshot systems,
  WaypointSymbol startSymbol,
  Set<WaypointSymbol> symbols,
) {
  final start = systems.waypoint(startSymbol);
  final waypoints = symbols
      // ignore start symbol in the symbols list. Could also throw.
      .where((s) => s != startSymbol)
      .map((s) => systems.waypoint(s))
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
int fuelUsedByDistance(double distance, ShipNavFlightMode flightMode) {
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
    throw UnimplementedError('Unimplemented $flightMode for $travelType');
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
  SystemRecord a,
  SystemRecord b, {
  required int shipSpeed,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  if (a.symbol == b.symbol) {
    throw ArgumentError('Cannot jump to the same system ${a.symbol}.');
  }
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
  return (15 + distance * 0.3).round();
}

/// Returns the cooldown time after jumping between two systems.
int cooldownTimeForJumpBetweenSystems(SystemRecord a, SystemRecord b) {
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
  SystemsSnapshot systems,
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
  final startWaypoint = systems.waypoint(start);
  final startJumpGate = systems.jumpGateWaypointForSystem(start.system)!;
  if (startJumpGate.symbol != start) {
    _addSubPlanWithinSystem(
      systems,
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
    final startJumpgate = systems.jumpGateWaypointForSystem(startSymbol)!;
    final endJumpGate = systems.jumpGateWaypointForSystem(endSymbol)!;
    final isLastJump = i == jumpPlan.route.length - 2;
    actions.add(
      _jumpAction(systems, startJumpgate, endJumpGate, isLastJump: isLastJump),
    );
  }
  final endWaypoint = systems.waypoint(end);
  final endJumpGate = systems.jumpGateWaypointForSystem(end.system)!;
  if (endJumpGate.symbol != end) {
    _addSubPlanWithinSystem(
      systems,
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
  SystemsSnapshot systems,
  List<RouteAction> route,
  SystemWaypoint start,
  SystemWaypoint end,
  ShipSpec shipSpec, {
  required bool Function(WaypointSymbol) sellsFuel,
}) {
  final actions = findRouteWithinSystem(
    systems,
    shipSpec,
    start: start.symbol,
    end: end.symbol,
    sellsFuel: sellsFuel,
  );
  // This should not be possible.
  if (actions == null) {
    throw ArgumentError(
      'Cannot find route within system from '
      '${start.symbol} to ${end.symbol}',
    );
  }
  route.addAll(actions);
}

RouteAction _jumpAction(
  SystemsSnapshot systems,
  SystemWaypoint start,
  SystemWaypoint end, {
  required bool isLastJump,
}) {
  final startSystem = systems.systemRecordBySymbol(start.system);
  final endSystem = systems.systemRecordBySymbol(end.system);
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
    required SystemsSnapshot systems,
    required SystemConnectivity systemConnectivity,
    required JumpCache jumpCache,
    required bool Function(WaypointSymbol) sellsFuel,
  }) : _systemsSnapshot = systems,
       _sellsFuel = sellsFuel,
       _systemConnectivity = systemConnectivity,
       _jumpCache = jumpCache;

  /// Create a new route planner from a systems cache.
  RoutePlanner.fromSystemsSnapshot(
    SystemsSnapshot systems,
    SystemConnectivity systemConnectivity, {
    required bool Function(WaypointSymbol) sellsFuel,
  }) : this(
         systems: systems,
         systemConnectivity: systemConnectivity,
         jumpCache: JumpCache(),
         sellsFuel: sellsFuel,
       );

  // SystemsSnapshot is all systems we knew about at the time of creation.
  final SystemsSnapshot _systemsSnapshot;

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
    if (!_systemConnectivity.existsJumpPathBetween(start.system, end.system)) {
      return null;
    }

    // Look up in the jump cache, if so, create a plan from that.
    final jumpPlan = _jumpCache.lookupJumpPlan(
      fromSystem: start.system,
      toSystem: end.system,
    );
    if (jumpPlan != null) {
      return routePlanFromJumpPlan(
        _systemsSnapshot,
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
      _systemsSnapshot,
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
      logger.warn(
        'planning $start to $end '
        'took ${approximateDuration(planningDuration)}',
      );
    }

    // walk backwards from end through symbols to build the route
    // we could alternatively build it forward and then fix the jump durations
    // after.
    final route = <RouteAction>[];
    var isLastJump = true;
    for (var i = symbols.length - 1; i > 0; i--) {
      final current = symbols[i];
      final previous = symbols[i - 1];
      final previousWaypoint = _systemsSnapshot.waypoint(previous);
      final currentWaypoint = _systemsSnapshot.waypoint(current);
      if (previousWaypoint.system != currentWaypoint.system) {
        // Assume we jumped.
        route.add(
          _jumpAction(
            _systemsSnapshot,
            previousWaypoint,
            currentWaypoint,
            isLastJump: isLastJump,
          ),
        );
        isLastJump = false;
      } else {
        _addSubPlanWithinSystem(
          _systemsSnapshot,
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
      _systemsSnapshot,
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
      logger.warn(
        'planning $start to $end '
        'took ${approximateDuration(planningDuration)}',
      );
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
      return _planWithinSystem(shipSpec, start: start, end: end);
    }
    // plan a route between systems
    return _planJump(shipSpec, start: start, end: end);
  }
}

/// Plan a route through a series of waypoints.
RoutePlan? planRouteThrough(
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
    final plan = routePlanner.planRoute(shipSpec, start: start, end: end);
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
    ..writeln(
      '${plan.startSymbol} to ${plan.endSymbol} '
      'speed: ${plan.shipSpeed} max-fuel: ${plan.fuelCapacity}',
    );
  for (final action in plan.actions) {
    buffer.writeln(
      '${action.type.name.padRight(14)}  ${action.startSymbol}  '
      '${action.endSymbol} ${approximateDuration(action.duration)}'
      ' ${action.fuelUsed} fuel',
    );
  }
  buffer.writeln(
    'in ${approximateDuration(plan.duration)} uses ${plan.fuelUsed} fuel',
  );
  return buffer.toString();
}

/// Compute the nearest shipyard to the given start.
Future<ShipyardListing?> nearestShipyard(
  RoutePlanner routePlanner,
  ShipyardListingSnapshot shipyards,
  Ship ship,
) async {
  final start = ship.waypointSymbol;
  final listings = shipyards.inSystem(start.system);

  // If not in this system.  Should list all shipyardListings.
  // Filter by ones which are reachable (e.g. if this ship can warp).
  // Pick the one with the shortest route.
  final systemConnectivity = routePlanner.systemConnectivity;

  final reachableShipyards = listings.where((listing) {
    return systemConnectivity.existsJumpPathBetween(
      start.system,
      listing.waypointSymbol.system,
    );
  });
  // Sort by system distance.
  final listing = minBy(reachableShipyards, (listing) {
    return routePlanner
        .planRoute(ship.shipSpec, start: start, end: listing.waypointSymbol)!
        .duration;
  });
  return listing;
}

/// Compute the travel time to the given waypoint considering the current ship
/// location.
Duration travelTimeTo(
  RoutePlanner routePlanner,
  Ship ship,
  WaypointSymbol waypoint,
) {
  final route = routePlanner.planRoute(
    ship.shipSpec,
    start: ship.waypointSymbol,
    end: waypoint,
  );
  final routeDuration = route!.duration;
  if (ship.isInTransit) {
    return routeDuration + ship.nav.route.timeUntilArrival();
  }
  return routeDuration;
}
