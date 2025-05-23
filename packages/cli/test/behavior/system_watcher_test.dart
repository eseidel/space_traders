import 'package:cli/behavior/system_watcher.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockChartingStore extends Mock implements ChartingStore {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockWaypointTraitStore extends Mock implements WaypointTraitStore {}

class _MockTransactionStore extends Mock implements TransactionStore {}

void main() {
  test('advanceSystemWatcher smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
    final waypoint = Waypoint.test(waypointSymbol);

    final systemWaypoint = SystemWaypoint.test(
      waypointSymbol,
      type: WaypointType.ARTIFICIAL_GRAVITY_WELL,
      position: WaypointPosition(0, 0, waypointSymbol.system),
    );
    when(
      () => caches.systems.waypoint(waypointSymbol),
    ).thenReturn(systemWaypoint);

    final system = System.test(waypointSymbol.system);
    when(
      () => caches.systems.systemBySymbol(waypointSymbol.system),
    ).thenReturn(system);
    registerFallbackValue(waypointSymbol.system);
    final shipSymbol = ShipSymbol.fromString('S-A');

    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.createChart(any())).thenAnswer(
      (invocation) => Future.value(
        CreateChart201Response(
          data: CreateChart201ResponseData(
            chart: Chart(
              waypointSymbol: waypointSymbol.waypoint,
              submittedBy: 'foo',
              submittedOn: DateTime(2021),
            ),
            agent: Agent.test().toOpenApi(),
            transaction: ChartTransaction(
              waypointSymbol: waypointSymbol.waypoint,
              shipSymbol: shipSymbol.symbol,
              totalPrice: 100,
              timestamp: DateTime(2021),
            ),
            waypoint: waypoint.toOpenApi(),
          ),
        ),
      ),
    );

    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
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
      () => caches.waypoints.hasMarketplace(waypointSymbol),
    ).thenAnswer((_) async => false);
    when(
      () => caches.waypoints.hasShipyard(waypointSymbol),
    ).thenAnswer((_) async => false);

    when(
      () => centralCommand.maxPriceAgeForSystem(waypointSymbol.system),
    ).thenReturn(const Duration(days: 3));
    registerFallbackValue(BehaviorSnapshot([]));
    registerFallbackValue(ShipSnapshot([]));
    when(
      () => centralCommand.waypointsToAvoidInSystem(
        any(),
        any(),
        waypointSymbol.system,
        shipSymbol,
      ),
    ).thenReturn([]);
    when(
      () => centralCommand.assignedSystemForSatellite(ship),
    ).thenReturn(waypointSymbol.system);
    final state = BehaviorState(
      shipSymbol,
      Behavior.charter,
    )..systemWatcherJob = SystemWatcherJob(systemSymbol: waypointSymbol.system);

    registerFallbackValue(waypoint);

    final chartingStore = _MockChartingStore();
    when(() => db.charting).thenReturn(chartingStore);
    when(() => chartingStore.addWaypoint(any())).thenAnswer((_) async => {});

    final waypointTraitStore = _MockWaypointTraitStore();
    when(() => db.waypointTraits).thenReturn(waypointTraitStore);
    when(() => waypointTraitStore.addAll(any())).thenAnswer((_) async {});

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);
    registerFallbackValue(Transaction.fallbackValue());
    when(() => transactionStore.insert(any())).thenAnswer((_) async {});

    registerFallbackValue(Agent.test());
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});

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

  test('waypointSymbolNeedingUpdate smoke test', () async {
    final db = _MockDatabase();
    final systems = SystemsSnapshot([]);
    final shipSymbol = ShipSymbol.fromString('S-A');
    final ship = Ship.test(shipSymbol);
    final waypointCache = _MockWaypointCache();
    final systemSymbol = SystemSymbol.fromString('S-A');
    final system = System.test(systemSymbol);

    final symbol = await waypointSymbolNeedingUpdate(
      db,
      systems,
      ship,
      system,
      maxAge: const Duration(days: 3),
      waypointCache: waypointCache,
      filter: null,
    );
    expect(symbol, isNull);
  });
}
