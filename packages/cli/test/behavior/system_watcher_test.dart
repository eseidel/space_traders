import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/system_watcher.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockWaypoint extends Mock implements Waypoint {}

void main() {
  test('advanceSystemWatcher smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final waypoint = _MockWaypoint();
    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
    when(() => waypoint.symbol).thenReturn(waypointSymbol.waypoint);
    when(() => waypoint.systemSymbol).thenReturn(waypointSymbol.system);
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypoint.chart).thenReturn(Chart());

    final systemWaypoint = SystemWaypoint(
      symbol: waypointSymbol.waypoint,
      type: WaypointType.ARTIFICIAL_GRAVITY_WELL,
      x: 0,
      y: 0,
    );
    when(() => caches.systems.waypoint(waypointSymbol))
        .thenReturn(systemWaypoint);

    final system = System(
      symbol: waypointSymbol.system,
      sectorSymbol: waypointSymbol.sector,
      type: SystemType.BLACK_HOLE,
      x: 0,
      y: 0,
    );
    when(() => caches.systems[waypointSymbol.systemSymbol]).thenReturn(system);
    registerFallbackValue(waypointSymbol.systemSymbol);

    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.createChart(any())).thenAnswer(
      (invocation) => Future.value(
        CreateChart201Response(
          data: CreateChart201ResponseData(chart: Chart(), waypoint: waypoint),
        ),
      ),
    );

    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.system);
    final shipFuel = ShipFuel(capacity: 0, current: 0);
    when(() => ship.fuel).thenReturn(shipFuel);

    registerFallbackValue(waypointSymbol);
    when(() => caches.waypoints.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(() => caches.waypoints.hasMarketplace(waypointSymbol))
        .thenAnswer((_) async => false);
    when(() => caches.waypoints.hasShipyard(waypointSymbol))
        .thenAnswer((_) async => false);

    when(() => centralCommand.maxPriceAgeForSystem(waypointSymbol.systemSymbol))
        .thenReturn(const Duration(days: 3));
    when(
      () => centralCommand
          .shortenMaxPriceAgeForSystem(waypointSymbol.systemSymbol),
    ).thenReturn(const Duration(days: 1));
    when(
      () => centralCommand.waypointsToAvoidInSystem(
        waypointSymbol.systemSymbol,
        shipSymbol,
      ),
    ).thenReturn([]);
    when(() => centralCommand.assignedSystemForSatellite(ship))
        .thenReturn(waypointSymbol.systemSymbol);
    final state = BehaviorState(shipSymbol, Behavior.charter)
      ..systemWatcherJob =
          SystemWatcherJob(systemSymbol: waypointSymbol.systemSymbol);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceSystemWatcher(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    expect(waitUntil, isNull);
  });
}
