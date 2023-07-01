import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/route.dart';
import 'package:collection/collection.dart';

// https://discord.com/channels/792864705139048469/792864705139048472/1121165658151997440
// Planned route from X1-CX76-69886Z to X1-XH63-75510F under fuel: 1200
// Jumpgate        X1-CX76-69886Z  ->      X1-FT95-48712C  172s
// Warp(DRIFT)     X1-FT95-48712C  ->      X1-JA5-77551C   10168s
// Refuel          X1-JA5-77551C
// Warp(CRUISE)    X1-JA5-77551C   ->      X1-M87-58481Z   669s
// Refuel          X1-M87-58481Z

// https://discord.com/channels/792864705139048469/792864705139048472/1121137672245747774
// Planned route X1-CX76 to X1-XH63 under fuel=1200, speed=30
// mode           from     to       fuel    duration
// -------------  -------  -------  ------  ----------
// JUMP           X1-RV19  X1-CX76  4->4    189s
// JUMP           X1-CX76  X1-FT95  4->4    172s
// WARP (DRIFT)   X1-FT95  X1-YN35  4->3    7915s
// WARP (CRUISE)  X1-YN35  X1-JA5   3->0    490s
// REFUEL         X1-JA5   X1-JA5   0->4    5s
// WARP (CRUISE)  X1-JA5   X1-M87   4->0    669s
// REFUEL         X1-M87   X1-M87   0->4    5s
// WARP (CRUISE)  X1-M87   X1-XC58  4->1    446s
// JUMP           X1-XC58  X1-UH63  1->1    189s
// JUMP           X1-UH63  X1-XH63  1->1    162s
// Total duration 10242s

enum RouteActionType {
  jump,
  // REFUEL,
  // NAV_DRIFT,
  // NAV_BURN,
  navCruise,
  // WARP_DRIFT,
  // WARP_CRUISE,
}

class RouteAction {
  RouteAction({
    required this.startSymbol,
    required this.endSymbol,
    required this.type,
    required this.duration,
    required this.cooldown,
  });
  final String startSymbol;
  final String endSymbol;
  final RouteActionType type;
  final int duration;
  final int cooldown;
}

typedef WaypointSymbol = String;
typedef Element = (WaypointSymbol, int);

class RoutePlan {
  RoutePlan({
    required this.fuelCapacity,
    required this.shipSpeed,
    required this.actions,
  });
  final int fuelCapacity;
  final int shipSpeed;
  final List<RouteAction> actions;
}

/// Plan a route between two waypoints.
RoutePlan? planRoute(
  SystemsCache systemCache, {
  required SystemWaypoint start,
  required SystemWaypoint end,
  required int fuelCapacity,
  required int shipSpeed,
}) {
// frontier = PriorityQueue()
// frontier.put(start, 0)
// came_from = dict()
// cost_so_far = dict()
// came_from[start] = None
// cost_so_far[start] = 0

// while not frontier.empty():
//    current = frontier.get()

//    if current == goal:
//       break

//    for next in graph.neighbors(current):
//       new_cost = cost_so_far[current] + graph.cost(current, next)
//       if next not in cost_so_far or new_cost < cost_so_far[next]:
//          cost_so_far[next] = new_cost
//          priority = new_cost + heuristic(goal, next)
//          frontier.put(next, priority)
//          came_from[next] = current

  Iterable<WaypointSymbol> neighborsFor(WaypointSymbol symbol) sync* {
    final waypoint = systemCache.waypointFromSymbol(symbol);
    if (waypoint.isJumpGate) {
      final systems = systemCache.connectedSystems(waypoint.systemSymbol);
      for (final system in systems) {
        yield systemCache.jumpGateWaypointForSystem(system.symbol)!.symbol;
      }
    } else {
      final otherWaypoints =
          systemCache.waypointsInSystem(waypoint.systemSymbol);
      for (final otherWaypoint in otherWaypoints) {
        if (otherWaypoint.symbol != waypoint.symbol) {
          yield otherWaypoint.symbol;
        }
      }
    }
  }

  int approximateTimeBetween(SystemWaypoint a, WaypointSymbol bSymbol) {
    if (a.symbol == bSymbol) {
      return 0;
    }
    final b = systemCache.waypointFromSymbol(bSymbol);
    if (a.systemSymbol == b.systemSymbol) {
      return a.position.distanceTo(b.position) ~/ shipSpeed;
    }
    final aSystem = systemCache.systemBySymbol(a.systemSymbol);
    final aGate = aSystem.jumpGateWaypoint;
    if (aGate == null) {
      throw Exception('No jump gate in system ${a.systemSymbol}');
    }
    final bSystem = systemCache.systemBySymbol(b.systemSymbol);
    final bGate = bSystem.jumpGateWaypoint;
    if (bGate == null) {
      throw Exception('No jump gate in system ${b.systemSymbol}');
    }
    final systemDistance = aSystem.distanceTo(bSystem);
    final aTimeToGate = a.distanceTo(aGate) ~/ shipSpeed;
    final bTimeToGate = b.distanceTo(bGate) ~/ shipSpeed;
    // distance / 10 is an approximation of the cooldown time for a jump gate.
    return aTimeToGate + bTimeToGate + systemDistance ~/ 10;
  }

  int timeBetween(WaypointSymbol aSymbol, WaypointSymbol bSymbol) {
    if (aSymbol == bSymbol) {
      return 0;
    }
    final a = systemCache.waypointFromSymbol(aSymbol);
    final b = systemCache.waypointFromSymbol(bSymbol);
    return approximateTimeBetween(a, b.symbol);
  }

  final frontier = PriorityQueue<Element>((a, b) => a.$2.compareTo(b.$2))
    ..add((start.symbol, 0));
  final cameFrom = <WaypointSymbol, WaypointSymbol>{};
  final costSoFar = <WaypointSymbol, int>{};
  costSoFar[start.symbol] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    if (current.$1 == end.symbol) {
      break;
    }
    for (final next in neighborsFor(current.$1)) {
      final newCost = costSoFar[current.$1]! + timeBetween(current.$1, next);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost + approximateTimeBetween(end, next);
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
  while (current != start.symbol) {
    final previous = cameFrom[current]!;
    final previousWaypoint = systemCache.waypointFromSymbol(previous);
    final currentWaypoint = systemCache.waypointFromSymbol(current);
    final duration = flightTimeWithinSystemInSeconds(
      previousWaypoint,
      currentWaypoint,
      shipSpeed: shipSpeed,
    );
    const cooldown = 0;
    route.add(
      RouteAction(
        startSymbol: previous,
        endSymbol: current,
        type: RouteActionType.navCruise,
        duration: duration,
        cooldown: cooldown,
      ),
    );
    current = previous;
  }

  return RoutePlan(
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    actions: route.reversed.toList(),
  );
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final systemsCache = await SystemsCache.load(
    fs,
    cacheFilePath: 'backups/6-24-23/systems.json',
  );
  const startSymbol = 'X1-CX76-69886Z';
  const endSymbol = 'X1-XH63-75510F';
  // const fuelLimit = 1200;
  // const shipSpeed = 30;
  // const canWarp = false;

  // Always optimize for time right now?
  // Ignoring warps for now.

  final start = systemsCache.waypointFromSymbol(startSymbol);
  final end = systemsCache.waypointFromSymbol(endSymbol);

  logger
    ..info(start.toString())
    ..info(end.toString());

  final plan = planRoute(
    systemsCache,
    start: start,
    end: end,
    fuelCapacity: 1200,
    shipSpeed: 30,
  );
  if (plan == null) {
    logger.err('No route found');
    return;
  }
  logger.info(plan.actions.toString());
}
