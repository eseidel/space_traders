import 'package:cli/cli.dart';
import 'package:cli/cli_args.dart';

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
  await runOffline(
    args,
    command,
    addArgs: (ArgParser parser) {
      parser.addOption(
        'ship',
        abbr: 't',
        help: 'Ship type used for calculations',
        allowed: ShipType.values.map(argFromShipType),
        defaultsTo: argFromShipType(ShipType.COMMAND_FRIGATE),
      );
    },
  );
}

WaypointSymbol waypointFromArg(
  SystemsSnapshot systems,
  String arg, {
  required String name,
}) {
  try {
    return WaypointSymbol.fromString(arg);
  } on FormatException {
    try {
      final system = SystemSymbol.fromString(arg);
      final jumpGate = systems.jumpGateWaypointForSystem(system)!;
      return jumpGate.symbol;
    } on FormatException {
      throw FormatException(
        'Invalid $name: $arg. '
        'Expected a waypoint symbol or system symbol.',
      );
    }
  }
}

Future<void> command(Database db, ArgResults argResults) async {
  final shipType = shipTypeFromArg(argResults['ship'] as String);
  final args = argResults.rest;
  if (args.length != 2) {
    logger.err('Usage: plan_route START END');
    return;
  }

  final systemsCache = await db.systems.snapshotAllSystems();
  final start = waypointFromArg(systemsCache, args[0], name: 'start');
  final end = waypointFromArg(systemsCache, args[1], name: 'end');

  final routePlanner = await defaultRoutePlanner(db);

  final shipyardShips = db.shipyardShips;
  final ship = await shipyardShips.get(shipType);

  final routeStart = DateTime.timestamp();
  final plan = routePlanner.planRoute(ship!.shipSpec, start: start, end: end);
  final routeEnd = DateTime.timestamp();
  final duration = routeEnd.difference(routeStart);
  if (plan == null) {
    logger.err('No route found (${duration.inMilliseconds}ms)');
  } else {
    logger
      ..info('Route found (${duration.inMilliseconds}ms)')
      ..info(describeRoutePlan(plan));
  }
}
