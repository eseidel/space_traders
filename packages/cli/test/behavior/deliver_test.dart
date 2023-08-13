import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/deliver.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:more/collection.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockBehaviorState extends Mock implements BehaviorState {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceDeliver smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final shipNav = _MockShipNav();
    final shipyardPrices = _MockShipyardPrices();
    final shipCache = _MockShipCache();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.ships).thenReturn(shipCache);

    final now = DateTime(2021);
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S-1');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);

    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => agentCache.headquartersSymbol).thenReturn(symbol);
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);

    const fuelCapacity = 100;
    when(() => ship.fuel)
        .thenReturn(ShipFuel(current: 100, capacity: fuelCapacity));
    final shipEngine = _MockShipEngine();
    when(() => ship.engine).thenReturn(shipEngine);
    const shipSpeed = 10;
    when(() => shipEngine.speed).thenReturn(shipSpeed);

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
    when(() => state.jobIndex).thenReturn(0);
    when(() => state.buyJob).thenReturn(
      BuyJob(
        tradeSymbol: TradeSymbol.MOUNT_GAS_SIPHON_I,
        units: 10,
        buyLocation: symbol,
      ),
    );

    when(centralCommand.mountsNeededForAllShips)
        .thenReturn(Multiset.from([ShipMountSymbolEnum.GAS_SIPHON_I]));
    final routePlanner = _MockRoutePlanner();
    when(() => caches.routePlanner).thenReturn(routePlanner);
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(10);
    when(
      () => marketPrices.pricesFor(
        TradeSymbol.MOUNT_GAS_SIPHON_I,
        marketSymbol: any(named: 'marketSymbol'),
      ),
    ).thenReturn([
      MarketPrice(
        waypointSymbol: symbol,
        symbol: TradeSymbol.MOUNT_GAS_SIPHON_I,
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 101,
        tradeVolume: 10,
        timestamp: DateTime(2021),
      )
    ]);

    when(
      () => routePlanner.planRoute(
        start: symbol,
        end: symbol,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(
      const RoutePlan(
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
        actions: [],
        fuelUsed: 10,
      ),
    );

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceDeliver(
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
