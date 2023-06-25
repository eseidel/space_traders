import 'package:space_traders_cli/behavior/explorer.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/cli.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/actions.dart';
import 'package:space_traders_cli/printing.dart';

Future<void> _navigateToLocalWaypointAndDock(
  Api api,
  Caches caches,
  Ship ship,
  Waypoint destination,
  bool shouldDock,
) async {
  final navigateResult =
      await navigateToLocalWaypoint(api, ship, destination.symbol);
  final eta = navigateResult.nav.route.arrival;
  final flightTime = eta.difference(DateTime.now());
  logger.info('Expected in $flightTime.');
  if (shouldDock) {
    logger.info('Waiting to dock...');
    await Future<void>.delayed(flightTime);
    await dockIfNeeded(api, ship);
    await visitLocalMarket(api, caches, destination, ship);
    await visitLocalShipyard(api, caches.shipyardPrices, destination, ship);
    logger.info('Docked.');
  }
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.waypoints, myShips);

  final startSystemSymbol = ship.nav.systemSymbol;
  final startingSystem = caches.systems.systemBySymbol(startSystemSymbol);
  final jumpGate = await caches.waypoints.jumpGateForSystem(startSystemSymbol);
  final jumpGateWaypoint =
      caches.systems.jumpGateWaypointForSystem(startSystemSymbol);

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

  final shouldDock = logger.confirm('Wait to dock?', defaultValue: true);

  final currentWaypoint =
      await caches.waypoints.waypoint(ship.nav.waypointSymbol);
  if (currentWaypoint.hasMarketplace && ship.shouldRefuel) {
    final market = await caches.markets.marketForSymbol(currentWaypoint.symbol);
    await refuelIfNeededAndLog(
      api,
      caches.marketPrices,
      caches.transactions,
      caches.agent,
      market!,
      ship,
    );
  }

  if (destWaypoint.systemSymbol == startingSystem.symbol) {
    await _navigateToLocalWaypointAndDock(
      api,
      caches,
      ship,
      destWaypoint,
      shouldDock,
    );
    return;
  }

  // This only handles a single jump at this point.

  // If we aren't at the jump gate, navigate to it.
  if (ship.nav.waypointSymbol != jumpGateWaypoint!.symbol) {
    final arrival = await navigateToLocalWaypointAndLog(
      api,
      ship,
      jumpGateWaypoint,
    );
    await Future<void>.delayed(durationUntil(arrival));
  }
  final jumpRequest = JumpShipRequest(systemSymbol: destSystem.symbol);
  await api.fleet.jumpShip(ship.symbol, jumpShipRequest: jumpRequest);
  // We don't need to wait after the jump cooldown.
  await _navigateToLocalWaypointAndDock(
    api,
    caches,
    ship,
    destWaypoint,
    shouldDock,
  );
}
