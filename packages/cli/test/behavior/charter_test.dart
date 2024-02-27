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
    final behaviors = BehaviorSnapshot([]);

    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
    final waypoint = Waypoint.test(
      waypointSymbol,
      type: WaypointType.PLANET,
    );

    final systemWaypoint = waypoint.toSystemWaypoint();
    when(() => caches.systems.waypoint(waypointSymbol))
        .thenReturn(systemWaypoint);

    final system = System(
      symbol: waypointSymbol.system,
      type: SystemType.BLACK_HOLE,
      position: const SystemPosition(0, 0),
    );
    when(() => caches.systems[waypointSymbol.system]).thenReturn(system);
    registerFallbackValue(waypointSymbol.system);
    when(() => caches.systemConnectivity.clusterIdForSystem(any()))
        .thenReturn(0);
    when(() => caches.systemConnectivity.systemSymbolsByClusterId(0))
        .thenReturn([waypointSymbol.system]);

    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.createChart(any())).thenAnswer(
      (invocation) => Future.value(
        CreateChart201Response(
          data: CreateChart201ResponseData(
            chart: Chart(),
            waypoint: waypoint.toOpenApi(),
          ),
        ),
      ),
    );

    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.systemString);
    final shipFuel = ShipFuel(capacity: 0, current: 0);
    when(() => ship.fuel).thenReturn(shipFuel);

    registerFallbackValue(waypointSymbol);
    when(() => caches.waypoints.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(() => caches.waypoints.fetchChart(any()))
        .thenAnswer((_) => Future.value(Chart()));
    when(() => caches.charting.addWaypoint(waypoint)).thenAnswer((_) async {});

    when(() => caches.waypoints.hasMarketplace(waypointSymbol))
        .thenAnswer((_) async => false);
    when(() => caches.waypoints.hasShipyard(waypointSymbol))
        .thenAnswer((_) async => false);

    when(
      () =>
          caches.systemConnectivity.systemsReachableFrom(waypointSymbol.system),
    ).thenReturn([]);

    when(
      () => centralCommand.chartAsteroidsInSystem(waypointSymbol.system),
    ).thenReturn(true);
    when(
      () => centralCommand.nextWaypointToChart(
        behaviors,
        caches.systems,
        caches.waypoints,
        caches.systemConnectivity,
        ship,
        maxJumps: 5,
      ),
    ).thenAnswer((_) async => null);
    final state = BehaviorState(shipSymbol, Behavior.charter);
    when(db.allBehaviorStates).thenAnswer((_) async => []);

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
        System.test(
          systemASymbol,
          waypoints: [
            SystemWaypoint.test(
              waypointAASymbol,
              type: WaypointType.ARTIFICIAL_GRAVITY_WELL,
            ),
            SystemWaypoint.test(
              waypointABSymbol,
              type: WaypointType.JUMP_GATE,
            ),
          ],
        ),
        System.test(
          systemBSymbol,
          position: const SystemPosition(10, 10),
          waypoints: [
            SystemWaypoint.test(
              waypointBASymbol,
              type: WaypointType.JUMP_GATE,
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
