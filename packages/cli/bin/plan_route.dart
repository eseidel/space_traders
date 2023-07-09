import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';

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

void main(List<String> args) async {
  await runOffline(args, command);
}

void planRouteAndLog(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  SystemWaypoint start,
  SystemWaypoint end,
) {
  final routeStart = DateTime.now();
  final plan = planRoute(
    systemsCache,
    systemConnectivity,
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

Future<void> command(FileSystem fs, List<String> args) async {
  final systemsCache = SystemsCache.loadFromCache(fs)!;
  final systemConnectivity = SystemConnectivity.fromSystemsCache(systemsCache);

  // final startSymbol = 'X1-QU45-24413B';
  const startSymbol = 'X1-S72-45410F';
  const endSymbol = 'X1-CP30-57877X';

  final start = systemsCache.waypointFromSymbol(startSymbol);
  final end = systemsCache.waypointFromSymbol(endSymbol);
  planRouteAndLog(systemsCache, systemConnectivity, start, end);
}
