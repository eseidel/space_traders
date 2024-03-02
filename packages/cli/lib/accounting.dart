import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:types/types.dart';

/// Compute the total value across all cargo for all ships.
Future<int> computeInventoryValue(
  ShipSnapshot ships,
  MarketPriceSnapshot marketPrices,
) async {
  final countByTradeSymbol = <TradeSymbol, int>{};
  for (final ship in ships.ships) {
    final inventory = ship.cargo.inventory;
    for (final item in inventory) {
      final symbol = item.tradeSymbol;
      final count = countByTradeSymbol[symbol] ?? 0;
      countByTradeSymbol[symbol] = count + item.units;
    }
  }
  final totalValue = countByTradeSymbol.entries.fold<int>(
    0,
    (total, entry) {
      final symbol = entry.key;
      final count = entry.value;
      final price = marketPrices.medianSellPrice(symbol);
      if (price == null) {
        logger.warn('No price for $symbol');
        return total;
      }
      final value = price * count;
      return total + value;
    },
  );
  return totalValue;
}
