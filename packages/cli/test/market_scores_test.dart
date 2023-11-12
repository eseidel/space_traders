import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scores.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

void main() {
  test('findBetterTradeLocation smoke test', () {
    final fs = MemoryFileSystem.test();
    final aSymbol = WaypointSymbol.fromString('S-A-A');
    final bSymbol = WaypointSymbol.fromString('S-A-B');
    final cSymbol = WaypointSymbol.fromString('S-A-C');
    final dSymbol = WaypointSymbol.fromString('S-A-D');
    final marketPrices = MarketPrices(
      [
        MarketPrice(
          waypointSymbol: aSymbol,
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 1,
          sellPrice: 2,
          tradeVolume: 100,
          timestamp: DateTime.timestamp(),
          activity: ActivityLevel.WEAK,
        ),
        MarketPrice(
          waypointSymbol: bSymbol,
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 100,
          sellPrice: 200,
          tradeVolume: 100,
          timestamp: DateTime.timestamp(),
          activity: ActivityLevel.WEAK,
        ),
      ],
      fs: fs,
    );
    final shipLocation = cSymbol;
    const shipSymbol = ShipSymbol('A', 1);
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.systemSymbol).thenReturn(shipLocation.system);

    final systemsCache = SystemsCache(
      [
        System(
          symbol: shipLocation.system,
          sectorSymbol: shipLocation.sector,
          type: SystemType.BLUE_STAR,
          x: 0,
          y: 0,
          waypoints: [
            SystemWaypoint(
              symbol: aSymbol.waypoint,
              type: WaypointType.PLANET,
              x: 0,
              y: 0,
            ),
            SystemWaypoint(
              symbol: bSymbol.waypoint,
              type: WaypointType.PLANET,
              x: 0,
              y: 0,
            ),
            SystemWaypoint(
              symbol: shipLocation.waypoint,
              type: WaypointType.PLANET,
              x: 0,
              y: 0,
            ),
            SystemWaypoint(
              symbol: dSymbol.waypoint,
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            ),
          ],
        ),
      ],
      fs: fs,
    );

    CostedDeal? findNextDeal(Ship ship, WaypointSymbol startSymbol) {
      return null;
    }

    final logger = _MockLogger();
    final result = runWithLogger(
      logger,
      () => findBetterTradeLocation(
        systemsCache,
        marketPrices,
        findNextDeal,
        ship,
        avoidSystems: <SystemSymbol>{},
        profitPerSecondThreshold: 6,
      ),
    );
    verify(() => logger.detail('🛸#1  No deal found for A-1 at S-A')).called(1);
    verify(() => logger.info('No nearby markets for A-1')).called(1);
    expect(result, isNull);
  });
}
