import 'package:mocktail/mocktail.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/arbitrage.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:test/test.dart';

class MockPriceData extends Mock implements PriceData {}

class MockApi extends Mock implements Api {}

class MockShip extends Mock implements Ship {}

class MockWaypoint extends Mock implements Waypoint {}

void main() {
  test('findBestDeal', () async {
    final api = MockApi();
    final ship = MockShip();
    final currentWaypoint = MockWaypoint();
    when(() => currentWaypoint.symbol).thenReturn('a');
    final allMarkets = [
      Market(
        symbol: 'a',
        tradeGoods: [
          MarketTradeGood(
            symbol: TradeSymbol.COPPER.value,
            tradeVolume: 100,
            supply: MarketTradeGoodSupplyEnum.MODERATE,
            purchasePrice: 1,
            sellPrice: 2,
          )
        ],
      ),
      Market(
        symbol: 'b',
        imports: [
          TradeGood(symbol: TradeSymbol.COPPER, name: '', description: '')
        ],
      ),
    ];

    // We fail to find a deal with no price data.
    final deal = await findBestDeal(
      api,
      PriceData([]),
      ship,
      currentWaypoint,
      allMarkets,
    );
    expect(deal, null);

    final deal2 = await findBestDeal(
      api,
      PriceData([
        Price(
          waypointSymbol: 'b',
          symbol: TradeSymbol.COPPER.value,
          supply: MarketTradeGoodSupplyEnum.MODERATE,
          purchasePrice: 1,
          sellPrice: 2,
          tradeVolume: 100,
          timestamp: DateTime.now(),
        )
      ]),
      ship,
      currentWaypoint,
      allMarkets,
    );
    expect(deal2, isNotNull);
    expect(deal2!.destinationSymbol, 'b');
    expect(deal2.tradeSymbol, TradeSymbol.COPPER);
    expect(deal2.purchasePrice, 1);
    expect(deal2.sellPrice, 2);
    expect(deal2.profit, 1);
  });
}
