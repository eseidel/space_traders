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

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

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
    when(() => caches.systems.waypoint(waypointSymbol))
        .thenReturn(systemWaypoint);

    final system = System.test(waypointSymbol.system);
    when(() => caches.systems[waypointSymbol.system]).thenReturn(system);
    registerFallbackValue(waypointSymbol.system);

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

    when(() => ship.fleetRole).thenReturn(FleetRole.command);
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

    when(() => caches.waypoints.hasMarketplace(waypointSymbol))
        .thenAnswer((_) async => false);
    when(() => caches.waypoints.hasShipyard(waypointSymbol))
        .thenAnswer((_) async => false);

    when(() => centralCommand.maxPriceAgeForSystem(waypointSymbol.system))
        .thenReturn(const Duration(days: 3));
    when(
      () => centralCommand.shortenMaxPriceAgeForSystem(waypointSymbol.system),
    ).thenReturn(const Duration(days: 1));
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
    when(() => centralCommand.assignedSystemForSatellite(ship))
        .thenReturn(waypointSymbol.system);
    final state = BehaviorState(shipSymbol, Behavior.charter)
      ..systemWatcherJob =
          SystemWatcherJob(systemSymbol: waypointSymbol.system);

    registerFallbackValue(waypoint);

    registerFallbackValue(ChartingRecord.fallbackValue());
    when(() => db.upsertChartingRecord(any())).thenAnswer((_) async => {});

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
