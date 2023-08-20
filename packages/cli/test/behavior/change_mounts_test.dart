import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/change_mounts.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockBehaviorState extends Mock implements BehaviorState {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceChangeMounts smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    final shipCache = _MockShipCache();
    when(() => caches.ships).thenReturn(shipCache);
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    final routePlanner = _MockRoutePlanner();
    when(() => caches.routePlanner).thenReturn(routePlanner);

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbolEnum.SURVEYOR_I,
        name: '',
        requirements: ShipRequirements(),
      ),
    ]);
    when(() => agentCache.headquartersSymbol).thenReturn(symbol);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    final shipEngine = _MockShipEngine();
    when(() => shipEngine.speed).thenReturn(10);
    when(() => ship.engine).thenReturn(shipEngine);

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID_FIELD);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        description: '',
        name: '',
        symbol: WaypointTraitSymbolEnum.SHIPYARD,
      ),
    ]);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);

    registerFallbackValue(symbol);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    registerFallbackValue(symbol.systemSymbol);

    when(
      () => waypointCache.waypointsInSystem(any()),
    ).thenAnswer((_) => Future.value([waypoint]));

    when(() => centralCommand.templateForShip(ship)).thenReturn(
      ShipTemplate(
        frameSymbol: ShipFrameSymbolEnum.CARRIER,
        mounts: MountSymbolSet.from([
          ShipMountSymbolEnum.SURVEYOR_I,
          ShipMountSymbolEnum.SURVEYOR_II,
        ]),
      ),
    );
    when(() => centralCommand.unclaimedMountsAt(symbol))
        .thenReturn(MountSymbolSet.from([ShipMountSymbolEnum.SURVEYOR_II]));

    final state = _MockBehaviorState();

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceChangeMounts(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
        getNow: getNow,
      ),
    );
    expect(waitUntil, isNull);
  });
}
