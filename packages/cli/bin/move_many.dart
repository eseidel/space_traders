import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/navigation.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic.dart';
import 'package:cli/printing.dart';
import 'package:cli/ship_waiter.dart';

Future<List<Ship>> chooseShips(
  Api api,
  SystemsCache systemsCache,
  List<Ship> ships,
) async {
  // Can't just return the result of chooseOne directly without triggering
  // a type error?
  final choices = logger.chooseAny(
    'Which ships?',
    choices: ships,
    display: (ship) => shipDescription(ship, systemsCache),
  );
  return choices;
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  // Where to move?
  final hq = parseWaypointString(caches.agent.agent.headquarters);
  final startSystem = hq.system;
  final myShips = caches.ships.ships;

  // This should be connectedSystemsWithinJumpRangeFromSystem or similar.
  final startingSystem = caches.systems.systemBySymbol(startSystem);
  final jumpGate = await caches.waypoints.jumpGateForSystem(startSystem);
  final systemChoices = [
    connectedSystemFromSystem(startingSystem, 0),
    ...jumpGate!.connectedSystems,
  ];

  final destSystem = logger.chooseOne(
    'To which system?',
    choices: systemChoices,
    display: (system) => '${system.symbol} - ${system.distance}',
  );

  final destSystemWaypoints =
      await caches.waypoints.waypointsInSystem(destSystem.symbol);

  final destWaypoint = logger.chooseOne(
    'To where?',
    choices: destSystemWaypoints,
    display: waypointDescription,
  );

  // Select many from a list.
  final selectedShips = await chooseShips(api, caches.systems, myShips);
  printShips(selectedShips, caches.systems);

  final behaviorCache = await BehaviorCache.load(fs);
  final centralCommand = CentralCommand(behaviorCache, caches.ships);
  // Set a destination for each ship.
  for (final ship in selectedShips) {
    await behaviorCache.setBehavior(
      ship.symbol,
      BehaviorState(ship.symbol, Behavior.explorer),
    );
    await beingRouteAndLog(
      api,
      ship,
      caches.systems,
      centralCommand,
      destWaypoint.symbol,
    );
  }

  final waiter = ShipWaiter();
  final activeShipSymbols = selectedShips.map((s) => s.symbol).toSet();

  // Loop the logicLoop until all ships are idle.
  while (true) {
    await advanceShips(
      api,
      centralCommand,
      caches,
      waiter,
      shipFilter: (s) => activeShipSymbols.contains(s.symbol),
    );

    final earliestWaitUntil = waiter.earliestWaitUntil();
    // earliestWaitUntil can be past if an earlier ship needed to wait
    // but then later ships took longer than that wait time to process.
    if (earliestWaitUntil != null &&
        earliestWaitUntil.isAfter(DateTime.now())) {
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.now());
      // Extra space after emoji needed for windows powershell.
      logger.info(
        '⏱️  ${waitDuration.inSeconds}s until ${earliestWaitUntil.toLocal()}',
      );
      await Future<void>.delayed(earliestWaitUntil.difference(DateTime.now()));
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
