import 'package:cli/behavior/surveyor.dart';
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
  test('advanceSurveyor smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.systemString);
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbolEnum.SURVEYOR_I,
        name: '',
        requirements: ShipRequirements(),
      ),
    ]);
    when(() => ship.cooldown).thenReturn(
      Cooldown(
        shipSymbol: shipSymbol.symbol,
        totalSeconds: 0,
        remainingSeconds: 0,
      ),
    );

    when(() => caches.waypoints.hasMarketplace(waypointSymbol))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(waypointSymbol))
        .thenAnswer((_) async => false);
    when(() => caches.waypoints.canBeMined(waypointSymbol))
        .thenAnswer((_) async => true);

    when(
      () => caches.waypoints.waypointsInSystem(waypointSymbol.system),
    ).thenAnswer((_) async => []);

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
      ..extractionJob = ExtractionJob(
        source: waypointSymbol,
        marketForGood: const {},
        extractionType: ExtractionType.mine,
      );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

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
    // Successful completion returns null.
    expect(waitUntil, isNull);
  });
}
