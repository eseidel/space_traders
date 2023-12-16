import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/charter.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:file/memory.dart';
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

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceCharter smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final waypoint = _MockWaypoint();
    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
    when(() => waypoint.symbol).thenReturn('S-A-B');
    when(() => waypoint.systemSymbol).thenReturn('S-A');
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypoint.chart).thenReturn(Chart());

    final systemWaypoint = SystemWaypoint(
      symbol: 'S-A-B',
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
    when(() => caches.systemConnectivity.clusterIdForSystem(any()))
        .thenReturn(0);
    when(() => caches.systemConnectivity.systemSymbolsByClusterId(0))
        .thenReturn([waypointSymbol.systemSymbol]);

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

    when(
      () => caches.systemConnectivity
          .systemsReachableFrom(waypointSymbol.systemSymbol),
    ).thenReturn([]);

    when(
      () => centralCommand.nextWaypointToChart(
        caches.systems,
        caches.waypoints,
        caches.systemConnectivity,
        ship,
      ),
    ).thenAnswer((_) async => null);
    final state = BehaviorState(shipSymbol, Behavior.charter);

    final logger = _MockLogger();
    expect(
      () async => await runWithLogger(
        logger,
        () => advanceCharter(
          api,
          db,
          centralCommand,
          caches,
          state,
          ship,
          getNow: () => DateTime(2021),
        ),
      ),
      throwsA(isA<JobException>()),
    );
  });

  test('nextUnchartedWaypointSymbol', () async {
    // Make sure nextUnchartedWaypointSymbol returns waypoints in our current
    // system when they exist, otherwise a nearby system, otherwise null.

    final fs = MemoryFileSystem.test();

    const shipSymbol = ShipSymbol('S', 1);
    final systemASymbol = SystemSymbol.fromString('S-A');
    final waypointAASymbol = WaypointSymbol.fromString('S-A-A');
    final waypointABSymbol = WaypointSymbol.fromString('S-A-B');
    final systemBSymbol = SystemSymbol.fromString('S-B');
    final waypointBASymbol = WaypointSymbol.fromString('S-B-A');

    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.systemSymbol).thenReturn(systemASymbol.system);
    when(() => shipNav.waypointSymbol).thenReturn(waypointAASymbol.waypoint);

    final systemsCache = SystemsCache(
      [
        System(
          symbol: systemASymbol.system,
          sectorSymbol: systemASymbol.sector,
          type: SystemType.BLACK_HOLE,
          x: 0,
          y: 0,
          waypoints: [
            SystemWaypoint(
              symbol: waypointAASymbol.waypoint,
              type: WaypointType.ARTIFICIAL_GRAVITY_WELL,
              x: 0,
              y: 0,
            ),
            SystemWaypoint(
              symbol: waypointABSymbol.waypoint,
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            ),
          ],
        ),
        System(
          symbol: systemBSymbol.system,
          sectorSymbol: systemBSymbol.sector,
          type: SystemType.BLACK_HOLE,
          x: 10,
          y: 10,
          waypoints: [
            SystemWaypoint(
              symbol: waypointBASymbol.waypoint,
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            ),
          ],
        ),
      ],
      fs: fs,
    );
    final waypointCache = _MockWaypointCache();
    final systemConnectivity = SystemConnectivity.test({
      waypointBASymbol: {waypointABSymbol},
    });

    when(() => waypointCache.isCharted(waypointAASymbol))
        .thenAnswer((_) async => true);
    when(() => waypointCache.isCharted(waypointABSymbol))
        .thenAnswer((_) async => false);
    when(() => waypointCache.isCharted(waypointBASymbol))
        .thenAnswer((_) async => false);

    final logger = _MockLogger();

    await runWithLogger(logger, () async {
      final intraSystem = await nextUnchartedWaypointSymbol(
        systemsCache,
        waypointCache,
        systemConnectivity,
        ship,
        startSystemSymbol: systemASymbol,
      );
      expect(intraSystem, equals(waypointABSymbol));

      when(() => waypointCache.isCharted(waypointABSymbol))
          .thenAnswer((_) async => true);
      final interSystem = await nextUnchartedWaypointSymbol(
        systemsCache,
        waypointCache,
        systemConnectivity,
        ship,
        startSystemSymbol: systemASymbol,
      );
      expect(interSystem, equals(waypointBASymbol));
    });
  });
}
