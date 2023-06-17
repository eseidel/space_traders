import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

Iterable<MarketPrice> pricesForWaypoint(
  PriceData priceData,
  Waypoint waypoint,
) {
  final prices = priceData.pricesAtMarket(waypoint.symbol);
  if (prices.isEmpty) {
    logger.info('No prices for ${waypoint.symbol}');
  }
  return prices;
}

void logPrices(List<MarketPrice> prices) {
  for (final price in prices) {
    logger.info(price.toString());
  }
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  final priceData = await PriceData.load(fs);
  final hq = await waypointCache.getAgentHeadquarters();
  final systemResponse = await api.systems.getSystem(hq.systemSymbol);
  final system = systemResponse!.data;
  final jumpGateWaypoint = system.waypoints
      .firstWhereOrNull((w) => w.type == WaypointType.JUMP_GATE);

  final jumpGateResponse =
      await api.systems.getJumpGate(system.symbol, jumpGateWaypoint!.symbol);
  final jumpGate = jumpGateResponse!.data;
  final systemNames = [
    hq.systemSymbol,
    for (final system in jumpGate.connectedSystems) system.symbol
  ];

  final waypoints = [
    for (final systemName in systemNames)
      for (final waypoint in await waypointCache.waypointsInSystem(systemName))
        waypoint
  ];
  // Given a set of waypoints.
  // Look at the pricing data.
  final localPrices = [
    for (final waypoint in waypoints) ...pricesForWaypoint(priceData, waypoint)
  ];
  // Could use a cut-off (e.g. median) instead of keeping only one.

  // Collect the most expensive sell price for each symbol.
  final sellOpportunities = <MarketPrice>[];
  for (final tradeSymbol in TradeSymbol.values) {
    final prices = localPrices.where((p) => p.symbol == tradeSymbol.value);
    if (prices.isEmpty) {
      continue;
    }
    final sortedPrices =
        prices.sorted((a, b) => a.sellPrice.compareTo(b.sellPrice));
    sellOpportunities.add(sortedPrices.last);
  }

  // Now do the buy side.
  final purchaseOpportunities = <MarketPrice>[];
  for (final tradeSymbol in TradeSymbol.values) {
    final prices = localPrices.where((p) => p.symbol == tradeSymbol.value);
    if (prices.isEmpty) {
      continue;
    }
    final sortedPrices =
        prices.sorted((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
    purchaseOpportunities.add(sortedPrices.first);
  }

  // Find a route that connects them.
  final deals = <Deal>[];
  for (final sell in sellOpportunities) {
    for (final buy in purchaseOpportunities) {
      if (sell.symbol != buy.symbol) {
        continue;
      }
      final deal = Deal(
        sourceSymbol: buy.waypointSymbol,
        destinationSymbol: sell.waypointSymbol,
        purchasePrice: buy.purchasePrice,
        sellPrice: sell.sellPrice,
        tradeSymbol: TradeSymbol.fromJson(buy.symbol)!,
      );
      if (deal.profit <= 0) {
        continue;
      }
      deals.add(deal);
    }
  }

  final sortedDeals = deals.sorted((a, b) => b.profit.compareTo(a.profit));
  logDeals(sortedDeals);
}
