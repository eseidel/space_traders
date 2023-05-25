import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

SystemWaypoint _lookupWaypoint(
  String waypointSymbol,
  List<SystemWaypoint> systemWaypoints,
) {
  return systemWaypoints.firstWhere((w) => w.symbol == waypointSymbol);
}

String _shipDescription(Ship ship, List<SystemWaypoint> systemWaypoints) {
  final waypoint = _lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
  var string =
      '${ship.symbol} - ${ship.navStatusString} ${waypoint.type} ${ship.registration.role} ${ship.cargo.units}/${ship.cargo.capacity}';
  if (ship.crew.morale != 100) {
    string += ' (morale: ${ship.crew.morale})';
  }
  if (ship.averageCondition != 100) {
    string += ' (condition: ${ship.averageCondition})';
  }
  return string;
}

Future<void> _navigateAndDock(
  Api api,
  Ship ship,
  String waypointSymbol,
  bool shouldDock,
) async {
  final navigateResult = await navigateTo(api, ship, waypointSymbol);
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

  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);

  final systemResponse = await api.systems.getSystem(hq.system);
  final startingSystem = systemResponse!.data;
  final startingSystemWaypoints = startingSystem.waypoints;

  final myShips = await allMyShips(api).toList();
  final ship = logger.chooseOne(
    'Which ship?',
    choices: myShips,
    display: (ship) => _shipDescription(ship, startingSystemWaypoints),
  );

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
    await _navigateAndDock(api, ship, destWaypoint.symbol, shouldDock);
    return;
  }

  await navigateTo(api, ship, jumpGateWaypoint.symbol);
  final jumpRequest = JumpShipRequest(systemSymbol: destSystem.symbol);
  await api.fleet.jumpShip(ship.symbol, jumpShipRequest: jumpRequest);
  await _navigateAndDock(api, ship, destWaypoint.symbol, shouldDock);
}
