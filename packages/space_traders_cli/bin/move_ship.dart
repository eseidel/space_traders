import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

Future<void> _navigateToLocalWaypointAndDock(
  Api api,
  Ship ship,
  String waypointSymbol,
  bool shouldDock,
) async {
  final navigateResult =
      await navigateToLocalWaypoint(api, ship, waypointSymbol);
  final eta = navigateResult.nav.route.arrival;
  final flightTime = eta.difference(DateTime.now());
  logger.info('Expected in $flightTime.');
  if (shouldDock) {
    logger.info('Waiting to dock...');
    await Future<void>.delayed(flightTime);
    await api.fleet.dockShip(ship.symbol);
    logger.info('Docked.');
  }
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);

  final myShips = await allMyShips(api).toList();
  final ship = await chooseShip(api, waypointCache, myShips);

  final startingSystem =
      await waypointCache.systemBySymbol(ship.nav.systemSymbol);
  final jumpGate = await waypointCache.jumpGateForSystem(ship.nav.systemSymbol);
  final jumpGateWaypoint =
      await waypointCache.jumpGateWaypointForSystem(ship.nav.systemSymbol);

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
      await waypointCache.waypointsInSystem(destSystem.symbol);

  final destWaypoint = logger.chooseOne(
    'To where?',
    choices: destSystemWaypoints,
    display: waypointDescription,
  );

  final shouldDock = logger.confirm('Wait to dock?', defaultValue: true);

  if (destWaypoint.systemSymbol == startingSystem.symbol) {
    await _navigateToLocalWaypointAndDock(
      api,
      ship,
      destWaypoint.symbol,
      shouldDock,
    );
    return;
  }

  // This only handles a single jump at this point.

  // If we aren't at the jump gate, navigate to it.
  if (ship.nav.waypointSymbol != jumpGateWaypoint!.symbol) {
    final arrival =
        await navigateToLocalWaypointAndLog(api, ship, jumpGateWaypoint);
    await Future<void>.delayed(durationUntil(arrival));
  }
  final jumpRequest = JumpShipRequest(systemSymbol: destSystem.symbol);
  await api.fleet.jumpShip(ship.symbol, jumpShipRequest: jumpRequest);
  // We don't need to wait after the jump cooldown.
  await _navigateToLocalWaypointAndDock(
    api,
    ship,
    destWaypoint.symbol,
    shouldDock,
  );
}
