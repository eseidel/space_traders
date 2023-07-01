import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
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
    // required this.cooldown,
  });
  final String startSymbol;
  final String endSymbol;
  final RouteActionType type;
  final int duration;
  // final int cooldown;
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

  String get startSymbol => actions.first.startSymbol;
  String get endSymbol => actions.last.endSymbol;
}

Iterable<WaypointSymbol> _neighborsFor(
  SystemsCache systemsCache,
  WaypointSymbol symbol,
) sync* {
  final waypoint = systemsCache.waypointFromSymbol(symbol);
  // If we're currently at a jump gate, we can jump to any other jumpgate
  // connected to this one.
  if (waypoint.isJumpGate) {
    final systems = systemsCache.connectedSystems(waypoint.systemSymbol);
    for (final system in systems) {
      yield systemsCache.jumpGateWaypointForSystem(system.symbol)!.symbol;
    }
  } else {
    // Otherwise we can navigate to any other waypoint in this system.
    // TODO(eseidel): This needs to enforce fuelCapacity.
    final otherWaypoints =
        systemsCache.waypointsInSystem(waypoint.systemSymbol);
    for (final otherWaypoint in otherWaypoints) {
      if (otherWaypoint.symbol != waypoint.symbol) {
        yield otherWaypoint.symbol;
      }
    }
  }
  // We don't currently support warping.
}

int _approximateTimeBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  WaypointSymbol bSymbol,
  int shipSpeed,
) {
  if (a.symbol == bSymbol) {
    return 0;
  }
  final b = systemsCache.waypointFromSymbol(bSymbol);
  if (a.systemSymbol == b.systemSymbol) {
    return a.position.distanceTo(b.position) ~/ shipSpeed;
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
  final aTimeToGate = a.distanceTo(aGate) ~/ shipSpeed;
  final bTimeToGate = b.distanceTo(bGate) ~/ shipSpeed;
  // Cooldown time for jumps is Math.min(60, distance / 10)
  // distance / 10 is an approximation of the cooldown time for a jump gate.
  // This assumes there are direct jumps in a line.
  return aTimeToGate + bTimeToGate + systemDistance ~/ 10;
}

int _timeBetween(
  SystemsCache systemsCache,
  WaypointSymbol aSymbol,
  WaypointSymbol bSymbol,
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
    for (final next in _neighborsFor(systemsCache, current.$1)) {
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
    logger.info("cameFrom doesn't contain end");
    return null;
  }

  // walk backwards from end through cameFrom to build the route
  final route = <RouteAction>[];
  var current = end.symbol;
  while (current != start.symbol) {
    final previous = cameFrom[current]!;
    final previousWaypoint = systemsCache.waypointFromSymbol(previous);
    final currentWaypoint = systemsCache.waypointFromSymbol(current);
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
    current = previous;
  }

  return RoutePlan(
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    actions: route.reversed.toList(),
  );
}

String describeRoutePlan(RoutePlan plan) {
  final buffer = StringBuffer()
    ..writeln('Route ${plan.startSymbol} to ${plan.endSymbol} '
        'speed: ${plan.shipSpeed} max-fuel: ${plan.fuelCapacity}');
  for (final action in plan.actions) {
    buffer.writeln('${action.type.name.padRight(14)}  ${action.startSymbol}  '
        '${action.endSymbol}  '
        '${action.duration}s');
  }
  buffer.writeln(
    'Total duration ${plan.actions.fold<int>(0, (a, b) => a + b.duration)}s',
  );
  return buffer.toString();
}

void main(List<String> args) async {
  await runOffline(args, command);
}

void planRouteAndLog(
  SystemsCache systemsCache,
  SystemWaypoint start,
  SystemWaypoint end,
) {
  final routeStart = DateTime.now();
  final plan = planRoute(
    systemsCache,
    start: start,
    end: end,
    fuelCapacity: 1200,
    shipSpeed: 30,
  );
  final routeEnd = DateTime.now();
  final duration = routeEnd.difference(routeStart);
  if (plan == null) {
    logger.err('No route found (${duration.inMilliseconds}ms)');
  } else {
    logger
      ..info('Route found (${duration.inMilliseconds}ms)')
      ..info(describeRoutePlan(plan));
  }
}

class RouteTest {
  const RouteTest({
    required this.startSymbol,
    required this.endSymbol,
    required this.expectedTime,
    this.fuelCapacity = 1200,
    this.shipSpeed = 30,
  });
  final String startSymbol;
  final String endSymbol;
  final int fuelCapacity;
  final int shipSpeed;
  final Duration expectedTime;
}

Future<void> command(FileSystem fs, List<String> args) async {
  // final systemsCache = await SystemsCache.load(fs
  //   cacheFilePath: 'backups/6-24-23/systems.json',
  // );
  // const startSymbol = 'X1-CX76-69886Z';
  // const endSymbol = 'X1-XH63-75510F';
  // const fuelLimit = 1200;
  // const shipSpeed = 30;
  // const canWarp = false;

  // Always optimize for time right now?
  // Ignoring warps for now.

  // final start = systemsCache.waypointFromSymbol(startSymbol);
  // final end = systemsCache.waypointFromSymbol(endSymbol);
  // logger
  //   ..info(start.toString())
  //   ..info(end.toString());

  // final plan = planRoute(
  //   systemsCache,
  //   start: start,
  //   end: end,
  //   fuelCapacity: 1200,
  //   shipSpeed: 30,
  // );
  // if (plan == null) {
  //   logger.err('No route found');
  //   return;
  // }
  // logger.info(plan.actions.toString());

  final systemsCache = await SystemsCache.load(fs);
  final factionCache = FactionCache.loadFromCache(fs)!;
  // final startTime = DateTime.now();
  // // Plan routes between each pair of faction headquarters.
  // for (var i = 0; i < factions.length; i++) {
  //   final faction = factions[i];
  //   final nextFaction = factions[(i + 1) % factions.length];
  //   final hqSymbol = faction.headquarters;
  //   final nextHqSymbol = nextFaction.headquarters;
  //   final hq = systemsCache.waypointFromSymbol(hqSymbol);
  //   final nextHq = systemsCache.waypointFromSymbol(nextHqSymbol);
  //   logger.info('Routing from ${faction.symbol} ($hqSymbol) to '
  //       '${nextFaction.symbol} ($nextHqSymbol)');
  //   planRouteAndLog(systemsCache, hq, nextHq);
  // }
  // final endTime = DateTime.now();
  // logger.info('Total time: ${endTime.difference(startTime)}');

  // final tests = [
  //   const RouteTest(startSymbol: 'X1-YU85-99640B',
  //    endSymbol: 'X1-YU85-07121B', expectedTime: Duration(seconds: 25)),
  // ]

  // ETHEREAL only connects to 2 systems, so it will always be quick to test.
  final faction = factionCache.factionBySymbol(FactionSymbols.ETHEREAL);
  final hqSymbol = faction.headquarters;
  final hq = systemsCache.waypointFromSymbol(hqSymbol);
  final connectedSystems = systemsCache.connectedSystems(hq.systemSymbol);
  final connectedSystemWaypoints =
      systemsCache.waypointsInSystem(connectedSystems.first.symbol);
  final nearbyWaypoint = connectedSystemWaypoints.first;
  planRouteAndLog(systemsCache, hq, nearbyWaypoint);
}
