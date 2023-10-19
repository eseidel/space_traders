import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
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

class _MockSystem extends Mock implements System {}

class _MockWaypoint extends Mock implements Waypoint {}

void main() {
  test('advanceExplorer smoke test', () async {
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

    final system = System(
      symbol: waypointSymbol.system,
      sectorSymbol: waypointSymbol.sector,
      type: SystemType.BLACK_HOLE,
      x: 0,
      y: 0,
    );
    when(() => caches.systems.systemBySymbol(waypointSymbol.systemSymbol))
        .thenReturn(system);
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
    final shipFuel = ShipFuel(capacity: 100, current: 100);
    when(() => ship.fuel).thenReturn(shipFuel);

    registerFallbackValue(waypointSymbol);
    when(() => caches.waypoints.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(() => centralCommand.maxAgeForExplorerData)
        .thenReturn(const Duration(days: 3));
    when(centralCommand.shortenMaxAgeForExplorerData)
        .thenReturn(const Duration(days: 1));
    when(() => centralCommand.otherExplorerSystems(shipSymbol)).thenReturn([]);
    final state = BehaviorState(shipSymbol, Behavior.explorer);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceExplorer(
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

  test('nearestHeadquarters', () {
    final startSystemSymbol = SystemSymbol.fromString('A-B');
    final systemConnectivity = SystemConnectivity({startSystemSymbol: 1});
    final system = _MockSystem();
    final fs = MemoryFileSystem.test();
    final systems = <System>[system];
    when(() => system.symbol).thenReturn(startSystemSymbol.system);
    final systemsCache = SystemsCache(systems: systems, fs: fs);
    final factions = <Faction>[
      Faction(
        symbol: FactionSymbols.AEGIS,
        name: 'Aegis',
        headquarters: 'A-B-C',
        description: 'Aegis',
        isRecruiting: false,
      ),
    ];
    final hq = nearestHeadquarters(
      systemConnectivity,
      systemsCache,
      factions,
      startSystemSymbol,
    );
    expect(hq, WaypointSymbol.fromString('A-B-C'));
  });
}
