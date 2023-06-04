import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
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

  final hq = await waypointCache.getAgentHeadquarters();

  final systemResponse = await api.systems.getSystem(hq.systemSymbol);
  final startingSystem = systemResponse!.data;

  final myShips = await allMyShips(api).toList();
  final ship = await chooseShip(api, waypointCache, myShips);

  final jumpGateWaypoint = startingSystem.waypoints
      .firstWhereOrNull((w) => w.type == WaypointType.JUMP_GATE);

  final jumpGateResponse = await api.systems
      .getJumpGate(startingSystem.symbol, jumpGateWaypoint!.symbol);
  final jumpGate = jumpGateResponse!.data;

  final systemChoices = [
    ConnectedSystem(
      distance: 0,
      symbol: startingSystem.symbol,
      sectorSymbol: startingSystem.sectorSymbol,
      type: startingSystem.type,
      x: startingSystem.x,
      y: startingSystem.y,
    ),
    ...jumpGate.connectedSystems,
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
  await navigateToLocalWaypoint(api, ship, jumpGateWaypoint.symbol);
  final jumpRequest = JumpShipRequest(systemSymbol: destSystem.symbol);
  await api.fleet.jumpShip(ship.symbol, jumpShipRequest: jumpRequest);
  await _navigateToLocalWaypointAndDock(
    api,
    ship,
    destWaypoint.symbol,
    shouldDock,
  );
}
