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
  final factions = factionCache.factions;
  final startTime = DateTime.now();
  // Plan routes between each pair of faction headquarters.
  for (var i = 0; i < factions.length; i++) {
    final faction = factions[i];
    final nextFaction = factions[(i + 1) % factions.length];
    final hqSymbol = faction.headquarters;
    final nextHqSymbol = nextFaction.headquarters;
    final hq = systemsCache.waypointFromSymbol(hqSymbol);
    final nextHq = systemsCache.waypointFromSymbol(nextHqSymbol);
    logger.info('Routing from ${faction.symbol} ($hqSymbol) to '
        '${nextFaction.symbol} ($nextHqSymbol)');
    planRouteAndLog(systemsCache, hq, nextHq);
  }
  final endTime = DateTime.now();
  logger.info('Total time: ${endTime.difference(startTime)}');
}
