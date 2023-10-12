import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scores.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

void main() {
  test('findBetterTradeLocation smoke test', () {
    final systemsCache = _MockSystemsCache();
    final marketPrices = _MockMarketPrices();
    // TODO(eseidel): return multiple MarketPrices to test more of the logic.
    when(() => marketPrices.prices).thenReturn([]);

    final shipLocation = WaypointSymbol.fromString('W-A-Y');
    const shipSymbol = ShipSymbol('A', 1);
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.systemSymbol).thenReturn(shipLocation.system);

    final system = System(
      symbol: shipLocation.system,
      sectorSymbol: shipLocation.sector,
      type: SystemType.BLUE_STAR,
      x: 0,
      y: 0,
    );
    when(() => systemsCache.systemBySymbol(shipLocation.systemSymbol))
        .thenReturn(system);

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

    expect(result, isNull);
  });
}
