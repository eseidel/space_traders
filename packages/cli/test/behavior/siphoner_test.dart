import 'package:cli/behavior/siphoner.dart';
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
  test('advanceSiphoner smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
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
        symbol: ShipMountSymbolEnum.GAS_SIPHON_II,
        name: '',
        requirements: ShipRequirements(),
        strength: 10,
      ),
    ]);

    when(
      () => centralCommand.siphonJobForShip(
        db,
        caches.systems,
        caches.charting,
        caches.agent,
        ship,
      ),
    ).thenAnswer(
      (_) => Future.value(
        ExtractionJob(
          source: waypointSymbol,
          marketForGood: const {},
          extractionType: ExtractionType.siphon,
        ),
      ),
    );

    when(() => caches.waypoints.hasMarketplace(waypointSymbol))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(waypointSymbol))
        .thenAnswer((_) async => false);
    when(() => caches.waypoints.canBeSiphoned(waypointSymbol))
        .thenAnswer((_) async => true);

    // when(() => caches.ships.ships).thenReturn([ship]);

    final shipCargo = ShipCargo(capacity: 60, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);
    final state = BehaviorState(shipSymbol, Behavior.siphoner);

    final cooldownAfterSiphoning = Cooldown(
      shipSymbol: shipSymbol.symbol,
      remainingSeconds: 10,
      expiration: now.add(const Duration(seconds: 10)),
      totalSeconds: 21,
    );
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(
      () => fleetApi.siphonResources(
        shipSymbol.symbol,
      ),
    ).thenAnswer(
      (_) => Future.value(
        SiphonResources201Response(
          data: SiphonResources201ResponseData(
            cooldown: cooldownAfterSiphoning,
            siphon: Siphon(
              shipSymbol: shipSymbol.symbol,
              yield_: SiphonYield(
                symbol: TradeSymbol.LIQUID_HYDROGEN,
                units: 10,
              ),
            ),
            cargo: shipCargo,
          ),
        ),
      ),
    );
    registerFallbackValue(ExtractionRecord.fallbackValue());
    when(() => db.insertExtraction(any())).thenAnswer((_) async {});

    final logger = _MockLogger();

    // With the reactor expiration, we should wait.
    final reactorExpiration = now.add(const Duration(seconds: 10));
    when(() => ship.cooldown).thenReturn(
      Cooldown(
        shipSymbol: shipSymbol.symbol,
        totalSeconds: 0,
        remainingSeconds: 0,
        expiration: reactorExpiration,
      ),
    );
    final reactorWait = await runWithLogger(
      logger,
      () => advanceSiphoner(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
        getNow: getNow,
      ),
    );
    expect(reactorWait, reactorExpiration);

    // With no wait, we should be able to complete the siphoning.
    when(() => ship.cooldown).thenReturn(
      Cooldown(
        shipSymbol: shipSymbol.symbol,
        totalSeconds: 0,
        remainingSeconds: 0,
      ),
    );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    final waitUntil = await runWithLogger(
      logger,
      () => advanceSiphoner(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
        getNow: getNow,
      ),
    );
    // Will wait after siphoning to siphon again if cargo is not full.
    expect(waitUntil, cooldownAfterSiphoning.expiration);
    verify(() => ship.cooldown = cooldownAfterSiphoning).called(1);
  });
}
