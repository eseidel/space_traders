import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockBehaviorState extends Mock implements BehaviorState {}

class _MockAgent extends Mock implements Agent {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockShipyardTransaction extends Mock implements ShipyardTransaction {}

void main() {
  test('advanceBuyShip smoke test', () async {
    final api = _MockApi();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final shipNav = _MockShipNav();
    final shipyardPrices = _MockShipyardPrices();
    final shipCache = _MockShipCache();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.ships).thenReturn(shipCache);

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('A', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);

    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => agentCache.headquartersSymbol).thenReturn(symbol);
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);

    final waypoint = _MockWaypoint();
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbolEnum.SHIPYARD,
        name: '',
        description: '',
      )
    ]);

    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);

    registerFallbackValue(symbol);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(() => waypointCache.shipyardWaypointsForSystem(symbol.systemSymbol))
        .thenAnswer((_) => Future.value([waypoint]));
    when(() => waypointCache.waypointsInSystem(symbol.systemSymbol))
        .thenAnswer((_) => Future.value([waypoint]));
    when(() => shipCache.ships).thenReturn([ship]);
    when(() => shipCache.frameCounts).thenReturn({});
    final state = _MockBehaviorState();

    const shipType = ShipType.ORE_HOUND;
    when(() => shipyardPrices.medianPurchasePrice(shipType)).thenReturn(1);
    when(
      () => shipyardPrices.recentPurchasePrice(
        shipyardSymbol: symbol,
        shipType: shipType,
      ),
    ).thenReturn(1);

    when(
      () => centralCommand.shipTypeToBuy(
        ship,
        shipyardPrices,
        agentCache,
        symbol,
      ),
    ).thenReturn(shipType);

    final systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    when(() => systemsApi.getShipyard(symbol.system, symbol.waypoint))
        .thenAnswer(
      (_) => Future.value(
        GetShipyard200Response(
          data: Shipyard(
            symbol: symbol.waypoint,
            shipTypes: [
              ShipyardShipTypesInner(type: shipType),
            ],
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
            agent: agent,
            transaction: transaction,
            ship: ship, // Supposed to be the new ship, cheating for the mock.
          ),
        ),
      ),
    );
    when(() => api.fleet).thenReturn(fleetApi);

    when(() => centralCommand.maxMedianShipPriceMultipler).thenReturn(1.05);

    final logger = _MockLogger();
    expect(
      () async {
        final waitUntil = await runWithLogger(
          logger,
          () => advanceBuyShip(
            api,
            centralCommand,
            caches,
            state,
            ship,
            getNow: getNow,
          ),
        );
        return waitUntil;
      },
      throwsA(
        const JobException(
          'Purchased A-1 (SHIP_ORE_HOUND)!',
          Duration(minutes: 10),
          disable: DisableBehavior.allShips,
        ),
      ),
    );
  });
}
