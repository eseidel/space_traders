import 'package:cli/behavior/buy_ship.dart';
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

class _MockRoutePlan extends Mock implements RoutePlan {}

class _MockShip extends Mock implements Ship {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardTransaction extends Mock implements ShipyardTransaction {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockTransactionStore extends Mock implements TransactionStore {}

void main() {
  setUpAll(() {
    registerFallbackValue(ShipSpec.fallbackValue());
  });

  test('advanceBuyShip smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('A', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    const fuelCapacity = 100;
    when(
      () => ship.fuel,
    ).thenReturn(ShipFuel(current: 100, capacity: fuelCapacity));
    final shipEngine = _MockShipEngine();
    when(() => ship.engine).thenReturn(shipEngine);
    const shipSpeed = 30;
    when(() => shipEngine.speed).thenReturn(shipSpeed);
    when(() => ship.mounts).thenReturn([]);
    when(() => ship.modules).thenReturn([]);
    when(() => ship.reactor).thenReturn(
      ShipReactor(
        symbol: ShipReactorSymbolEnum.ANTIMATTER_I,
        name: 'name',
        description: 'description',
        powerOutput: 0,
        requirements: ShipRequirements(),
        condition: 1,
        integrity: 1,
        quality: 1,
      ),
    );

    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.systemString);

    final agent = Agent.test();
    registerFallbackValue(agent);
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});
    when(db.getMyAgent).thenAnswer((_) async => agent);

    when(
      () => caches.waypoints.waypointsInSystem(symbol.system),
    ).thenAnswer((_) async => []);

    const shipType = ShipType.HEAVY_FREIGHTER;
    final state = BehaviorState(shipSymbol, Behavior.buyShip)
      ..shipBuyJob = ShipBuyJob(
        shipType: shipType,
        shipyardSymbol: symbol,
        minCreditsNeeded: 10000,
      );

    final systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    when(
      () => systemsApi.getShipyard(symbol.systemString, symbol.waypoint),
    ).thenAnswer(
      (_) => Future.value(
        GetShipyard200Response(
          data: Shipyard(
            symbol: symbol.waypoint,
            modificationsFee: 0,
            shipTypes: [ShipyardShipTypesInner(type: shipType)],
          ),
        ),
      ),
    );
    final fleetApi = _MockFleetApi();
    final transaction = _MockShipyardTransaction();
    when(() => transaction.shipSymbol).thenReturn(shipSymbol.symbol);
    when(() => transaction.price).thenReturn(2);
    when(() => transaction.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => transaction.timestamp).thenReturn(DateTime(2021));
    when(() => transaction.shipType).thenReturn(shipType.value);
    when(
      () => fleetApi.purchaseShip(
        purchaseShipRequest: PurchaseShipRequest(
          shipType: shipType,
          waypointSymbol: symbol.waypoint,
        ),
      ),
    ).thenAnswer(
      (_) => Future.value(
        PurchaseShip201Response(
          data: PurchaseShip201ResponseData(
            agent: agent.toOpenApi(),
            transaction: transaction,
            // Supposed to be the new ship, cheating for the mock.
            ship: Ship.fallbackValue().toOpenApi(),
          ),
        ),
      ),
    );
    when(() => api.fleet).thenReturn(fleetApi);

    final route = _MockRoutePlan();
    when(
      () => caches.routePlanner.planRoute(any(), start: symbol, end: symbol),
    ).thenReturn(route);

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);

    registerFallbackValue(Transaction.fallbackValue());
    when(() => transactionStore.insert(any())).thenAnswer((_) async {});

    registerFallbackValue(ShipyardListing.fallbackValue());
    when(() => db.upsertShipyardListing(any())).thenAnswer((_) async {});
    registerFallbackValue(Ship.fallbackValue());
    when(() => db.upsertShip(any())).thenAnswer((_) async {});
    when(db.allShipyardListings).thenAnswer((_) async => []);
    when(db.allShips).thenAnswer((_) async => []);
    registerFallbackValue(ShipyardListingSnapshot([]));
    registerFallbackValue(ShipSnapshot([]));
    when(
      () => centralCommand.updateBuyShipJobIfNeeded(
        db,
        api,
        caches,
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async {});

    registerFallbackValue(ship.engine);
    when(() => caches.static.engines.add(any())).thenAnswer((_) async {});
    registerFallbackValue(ship.reactor);
    when(() => caches.static.reactors.add(any())).thenAnswer((_) async {});

    final logger = _MockLogger();
    expect(
      await runWithLogger(
        logger,
        () => advanceBuyShip(
          api,
          db,
          centralCommand,
          caches,
          state,
          ship,
          getNow: getNow,
        ),
      ),
      isNull,
    );
    verify(
      () =>
          logger.warn('🛸#1  command   Purchased S-1 (SHIP_HEAVY_FREIGHTER)!'),
    );
  });
}
