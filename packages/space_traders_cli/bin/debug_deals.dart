import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/queries.dart';

void main() async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);
  final marketCache = MarketCache(waypointCache);

  final priceData = await PriceData.load(fs);
  final ships = await allMyShips(api).toList();
  final ship = ships.first;

  final promptResponse = logger.prompt(
    'Which trade symbol? (Options: ${TradeSymbol.values.join(', ')}))',
  );

  final tradeSymbol = TradeSymbol.fromJson(promptResponse.toUpperCase().trim());
  if (tradeSymbol == null) {
    logger.err('Invalid trade symbol');
    return;
  }

  // For a given set of markets.
  // List all prices for a given symbol.
  // And find the best deal among those markets for said symbol.

  final connectedSystems =
      waypointCache.connectedSystems(ship.nav.systemSymbol);
  final markets = await connectedSystems
      .asyncExpand((s) => marketCache.marketsInSystem(s.symbol))
      .toList();

  logger.info('market: sell price, purchase price');
  for (final market in markets) {
    if (!market.allowsTradeOf(tradeSymbol.value)) {
      continue;
    }
    final sellPrice = estimateSellPrice(priceData, tradeSymbol, market);
    final purchasePrice = estimatePurchasePrice(priceData, tradeSymbol, market);
    logger.info('${market.symbol}: $sellPrice, $purchasePrice');
  }

  final deal = await findBestDealAcrossMarkets(
    priceData,
    ship,
    waypointCache,
    marketCache,
    markets,
  );

  if (deal != null) {
    logDeal(ship, deal);
  } else {
    logger.info('No deals found');
  }
}