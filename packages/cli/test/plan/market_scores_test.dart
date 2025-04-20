import 'package:cli/cache/market_price_snapshot.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/plan/market_scores.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

void main() {
  test('findBetterTradeLocation smoke test', () {
    final fs = MemoryFileSystem.test();
    final aSymbol = WaypointSymbol.fromString('S-A-A');
    final bSymbol = WaypointSymbol.fromString('S-A-B');
    final cSymbol = WaypointSymbol.fromString('S-A-C');
    final dSymbol = WaypointSymbol.fromString('S-A-D');
    final now = DateTime(2021);
    final marketPrices = MarketPriceSnapshot([
      MarketPrice(
        waypointSymbol: aSymbol,
        symbol: TradeSymbol.ADVANCED_CIRCUITRY,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 1,
        sellPrice: 2,
        tradeVolume: 100,
        timestamp: now,
        activity: ActivityLevel.WEAK,
      ),
      MarketPrice(
        waypointSymbol: bSymbol,
        symbol: TradeSymbol.ADVANCED_CIRCUITRY,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 200,
        tradeVolume: 100,
        timestamp: now,
        activity: ActivityLevel.WEAK,
      ),
    ]);
    final shipLocation = cSymbol;
    const shipSymbol = ShipSymbol('A', 1);
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.systemSymbol).thenReturn(shipLocation.systemString);

    final system = System.test(
      shipLocation.system,
      type: SystemType.BLUE_STAR,
      waypoints: [
        SystemWaypoint.test(aSymbol),
        SystemWaypoint.test(bSymbol),
        SystemWaypoint.test(shipLocation),
        SystemWaypoint.test(dSymbol, type: WaypointType.JUMP_GATE),
      ],
    );
    final systems = [system];
    final systemsCache = SystemsCache(systems, fs: fs);
    final systemConnectivity = _MockSystemConnectivity();
    registerFallbackValue(aSymbol.system);
    when(
      () => systemConnectivity.existsJumpPathBetween(any(), any()),
    ).thenReturn(true);

    CostedDeal? findNextDeal(Ship ship, WaypointSymbol startSymbol) {
      return null;
    }

    final logger = _MockLogger();
    final result = runWithLogger(
      logger,
      () => findBetterTradeLocation(
        systemsCache,
        systemConnectivity,
        marketPrices,
        ship,
        findDeal: findNextDeal,
        avoidSystems: <SystemSymbol>{},
        profitPerSecondThreshold: 6,
      ),
    );
    verify(
      () => logger.detail('🛸#1  command   No deal found for A-1 at S-A'),
    ).called(1);
    verify(() => logger.info('No nearby markets for A-1')).called(1);
    expect(result, isNull);
  });
}
