import 'package:cli/behavior/charter.dart';
import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockBehaviorStore extends Mock implements BehaviorStore {}

class _MockChartingStore extends Mock implements ChartingStore {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockChartingSnapshot extends Mock implements ChartingSnapshot {}

class _MockSystemsStore extends Mock implements SystemsStore {}

void main() {
  test('advanceCharter smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final systemsStore = _MockSystemsStore();
    when(() => db.systems).thenReturn(systemsStore);
    final ship = _MockShip();
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
    final waypoint = Waypoint.test(waypointSymbol, type: WaypointType.PLANET);

    final systemWaypoint = waypoint.toSystemWaypoint();
    when(
      () => caches.systems.waypoint(waypointSymbol),
    ).thenReturn(systemWaypoint);

    final system = System(
      symbol: waypointSymbol.system,
      type: SystemType.BLACK_HOLE,
      position: const SystemPosition(0, 0),
    );
    when(
      () => caches.systems.systemBySymbol(waypointSymbol.system),
    ).thenReturn(system);
    registerFallbackValue(waypointSymbol.system);
    when(
      () => caches.systemConnectivity.clusterIdForSystem(any()),
    ).thenReturn(0);
    when(
      () => caches.systemConnectivity.systemSymbolsByClusterId(0),
    ).thenReturn([waypointSymbol.system]);

    final chart = Chart(
      waypointSymbol: waypointSymbol.waypoint,
      submittedBy: 'foo',
      submittedOn: DateTime(2021),
    );

    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.createChart(any())).thenAnswer(
      (invocation) => Future.value(
        CreateChart201Response(
          data: CreateChart201ResponseData(
            chart: chart,
            waypoint: waypoint.toOpenApi(),
            transaction: ChartTransaction(
              waypointSymbol: waypointSymbol.waypoint,
              shipSymbol: shipSymbol.symbol,
              totalPrice: 100,
              timestamp: DateTime(2021),
            ),
            agent: Agent.test().toOpenApi(),
          ),
        ),
      ),
    );

    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.systemString);
    final shipFuel = ShipFuel(capacity: 0, current: 0);
    when(() => ship.fuel).thenReturn(shipFuel);

    registerFallbackValue(waypointSymbol);
    when(
      () => caches.waypoints.waypoint(any()),
    ).thenAnswer((_) => Future.value(waypoint));
    when(
      () => caches.waypoints.fetchChart(any()),
    ).thenAnswer((_) => Future.value(chart));

    when(
      () => caches.waypoints.hasMarketplace(waypointSymbol),
    ).thenAnswer((_) async => false);
    when(
      () => caches.waypoints.hasShipyard(waypointSymbol),
    ).thenAnswer((_) async => false);

    when(
      () =>
          caches.systemConnectivity.systemsReachableFrom(waypointSymbol.system),
    ).thenReturn([]);

    when(
      () => centralCommand.chartAsteroidsInSystem(waypointSymbol.system),
    ).thenReturn(true);
    registerFallbackValue(BehaviorSnapshot([]));
    registerFallbackValue(ShipSnapshot([]));
    registerFallbackValue(ChartingSnapshot([]));
    registerFallbackValue(Ship.fallbackValue());
    when(
      () => centralCommand.nextWaypointToChart(
        any(),
        any(),
        caches.systems,
        any(),
        caches.systemConnectivity,
        any(),
        maxJumps: config.charterMaxJumps,
      ),
    ).thenReturn(null);
    final state = BehaviorState(shipSymbol, Behavior.charter);
    final behaviorStore = _MockBehaviorStore();
    when(() => db.behaviors).thenReturn(behaviorStore);
    when(behaviorStore.all).thenAnswer((_) async => []);
    when(db.allShips).thenAnswer((_) async => []);

    final chartingStore = _MockChartingStore();
    when(() => db.charting).thenReturn(chartingStore);
    when(
      chartingStore.snapshotAllRecords,
    ).thenAnswer((_) async => ChartingSnapshot([]));

    when(
      systemsStore.snapshotAllSystems,
    ).thenAnswer((_) async => SystemsSnapshot([]));

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

    const shipSymbol = ShipSymbol('S', 1);
    final systemASymbol = SystemSymbol.fromString('S-A');
    final waypointAASymbol = WaypointSymbol.fromString('S-A-A');
    final waypointABSymbol = WaypointSymbol.fromString('S-A-B');
    final systemBSymbol = SystemSymbol.fromString('S-B');
    final waypointBASymbol = WaypointSymbol.fromString('S-B-A');

    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    when(() => ship.symbol).thenReturn(shipSymbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.systemSymbol).thenReturn(systemASymbol.system);
    when(() => shipNav.waypointSymbol).thenReturn(waypointAASymbol.waypoint);

    final systems = [
      System.test(
        systemASymbol,
        waypoints: [
          SystemWaypoint.test(
            waypointAASymbol,
            type: WaypointType.ARTIFICIAL_GRAVITY_WELL,
          ),
          SystemWaypoint.test(waypointABSymbol, type: WaypointType.JUMP_GATE),
        ],
      ),
      System.test(
        systemBSymbol,
        position: const SystemPosition(10, 10),
        waypoints: [
          SystemWaypoint.test(waypointBASymbol, type: WaypointType.JUMP_GATE),
        ],
      ),
    ];
    final systemsCache = SystemsSnapshot(systems);
    final systemConnectivity = SystemConnectivity.test({
      waypointBASymbol: {waypointABSymbol},
    });

    final chartingSnapshot = _MockChartingSnapshot();
    when(() => chartingSnapshot.isCharted(waypointAASymbol)).thenReturn(true);
    when(() => chartingSnapshot.isCharted(waypointABSymbol)).thenReturn(false);
    when(() => chartingSnapshot.isCharted(waypointBASymbol)).thenReturn(false);

    final logger = _MockLogger();

    await runWithLogger(logger, () async {
      final intraSystem = nextUnchartedWaypointSymbol(
        systemsCache,
        chartingSnapshot,
        systemConnectivity,
        ship,
        startSystemSymbol: systemASymbol,
      );
      expect(intraSystem, equals(waypointABSymbol));

      when(() => chartingSnapshot.isCharted(waypointABSymbol)).thenReturn(true);
      final interSystem = nextUnchartedWaypointSymbol(
        systemsCache,
        chartingSnapshot,
        systemConnectivity,
        ship,
        startSystemSymbol: systemASymbol,
      );
      expect(interSystem, equals(waypointBASymbol));
    });
  });
}
