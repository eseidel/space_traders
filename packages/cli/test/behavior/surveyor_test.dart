import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/surveyor.dart';
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
  test('advanceSurveyor smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

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

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID_FIELD);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbol.COMMON_METAL_DEPOSITS,
        name: 'name',
        description: 'description',
      ),
    ]);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);

    registerFallbackValue(symbol);
    when(() => caches.waypoints.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    registerFallbackValue(symbol.systemSymbol);

    when(
      () => caches.waypoints.waypointsInSystem(any()),
    ).thenAnswer((_) => Future.value([waypoint]));

    when(() => fleetApi.createSurvey(shipSymbol.symbol)).thenAnswer(
      (_) => Future.value(
        CreateSurvey201Response(
          data: CreateSurvey201ResponseData(
            surveys: [],
            cooldown: Cooldown(
              shipSymbol: shipSymbol.symbol,
              expiration: DateTime(2021),
              remainingSeconds: 1,
              totalSeconds: 1,
            ),
          ),
        ),
      ),
    );

    final state = BehaviorState(shipSymbol, Behavior.surveyor)
      ..mineJob = MineJob(mine: symbol, market: symbol);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceSurveyor(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
        getNow: getNow,
      ),
    );
    expect(waitUntil, DateTime(2021));
  });
}
