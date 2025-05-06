import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/plan/trading.dart';
import 'package:collection/collection.dart';
import 'package:types/prediction.dart';
import 'package:types/types.dart';

/// Callback to find the next deal for the given [ship]
/// if imagined to start at the given [startSymbol].
typedef FindDeal = CostedDeal? Function(Ship ship, WaypointSymbol startSymbol);

/// Find a better destination for the given trader [ship].
WaypointSymbol? findBetterTradeLocation(
  SystemsSnapshot systems,
  SystemConnectivity systemConnectivity,
  MarketPriceSnapshot marketPrices,
  Ship ship, {
  required FindDeal findDeal,
  required Set<SystemSymbol> avoidSystems,
  required int profitPerSecondThreshold,
}) {
  final search = _MarketSearch.start(
    marketPrices,
    systems,
    avoidSystems: avoidSystems,
  );
  final placement = _findBetterSystemForTrader(
    systems,
    systemConnectivity,
    search,
    ship,
    findDeal: findDeal,
    profitPerSecondThreshold: profitPerSecondThreshold,
  );
  return placement?.destinationSymbol;
}

/// Compute the score for each market based on the distance of each good's
/// price from the median price.
Map<SystemSymbol, int> scoreMarketSystems(
  MarketPriceSnapshot marketPrices, {
  int limit = 200,
}) {
  // Walk all markets in the market prices.  Get all goods for each market
  // compute the absolute distance for each good from the median price
  // sum up that value for the market and record that as the "market score".

  // First calculate median prices for all goods.
  final medianPurchasePrices = <TradeSymbol, int?>{};
  final medianSellPrices = <TradeSymbol, int?>{};
  for (final tradeSymbol in TradeSymbol.values) {
    medianPurchasePrices[tradeSymbol] = marketPrices.medianPurchasePrice(
      tradeSymbol,
    );
    medianSellPrices[tradeSymbol] = marketPrices.medianSellPrice(tradeSymbol);
  }

  final marketSystemScores = <SystemSymbol, int>{};
  for (final price in marketPrices.prices) {
    final market = price.waypointSymbol;
    final system = market.system;
    final medianPurchasePrice = medianPurchasePrices[price.tradeSymbol]!;
    final medianSellPrice = medianSellPrices[price.tradeSymbol]!;
    final purchaseScore = (price.purchasePrice - medianPurchasePrice).abs();
    final sellScore = (price.sellPrice - medianSellPrice).abs();
    final score = purchaseScore + sellScore;
    marketSystemScores[system] = (marketSystemScores[system] ?? 0) + score;
  }

  final sortedScores =
      marketSystemScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sortedScores.take(limit));
}

_ShipPlacement? _findBetterSystemForTrader(
  SystemsSnapshot systems,
  SystemConnectivity systemConnectivity,
  _MarketSearch search,
  Ship ship, {
  required FindDeal findDeal,
  required int profitPerSecondThreshold,
}) {
  final shipSymbol = ship.symbol;
  final shipSystem = systems.systemRecordBySymbol(ship.systemSymbol);

  while (true) {
    final closest = search.closestAvailableSystem(shipSystem);
    if (closest == null) {
      logger.info('No nearby markets for $shipSymbol');
      return null;
    }
    search.markUsed(closest);

    if (!systemConnectivity.existsJumpPathBetween(
      closest.symbol,
      shipSystem.symbol,
    )) {
      shipDetail(ship, 'Not reachable: $shipSymbol -> ${closest.symbol}');
      continue;
    }

    final score = search.scoreFor(closest.symbol);
    // This code assumes we're on the jump gate network.
    final systemJumpGate = systems.jumpGateWaypointForSystem(closest.symbol)!;
    final deal = findDeal(ship, systemJumpGate.symbol);
    if (deal == null) {
      shipDetail(ship, 'No deal found for $shipSymbol at ${closest.symbol}');
      search.markUsed(closest);
      continue;
    }
    final profitPerSecond = deal.expectedProfitPerSecond;
    if (profitPerSecond < profitPerSecondThreshold) {
      shipDetail(
        ship,
        'Profit per second too low for $shipSymbol at '
        '${closest.symbol}, $profitPerSecond < $profitPerSecondThreshold',
      );
      search.markUsed(closest);
      continue;
    }
    final placement = _ShipPlacement(
      score: score,
      distance: shipSystem.distanceTo(closest).round(),
      profitPerSecond: profitPerSecond,
      destinationSymbol: systemJumpGate.symbol,
    );
    shipInfo(
      ship,
      'Found placement: ${creditsString(profitPerSecond)}/s '
      '${placement.score} ${placement.distance} '
      '${placement.destinationSymbol}',
    );
    shipInfo(ship, 'Potential: ${describeCostedDeal(deal)}');
    return placement;
  }
}

SystemRecord? _closestSystem(SystemRecord start, List<SystemRecord> systems) {
  return minBy(systems, (system) => start.distanceTo(system));
}

class _ShipPlacement {
  _ShipPlacement({
    required this.score,
    required this.distance,
    required this.profitPerSecond,
    required this.destinationSymbol,
  });

  final int score;
  final int distance;
  final int profitPerSecond;
  final WaypointSymbol destinationSymbol;
}

class _MarketSearch {
  _MarketSearch({
    required this.marketSystems,
    required this.marketSystemScores,
    required this.claimedSystemSymbols,
  });

  factory _MarketSearch.start(
    MarketPriceSnapshot marketPrices,
    SystemsSnapshot systems, {
    Set<SystemSymbol>? avoidSystems,
  }) {
    final marketSystemScores = scoreMarketSystems(marketPrices);
    final marketSystems =
        marketSystemScores.keys.map(systems.systemRecordBySymbol).toList();
    return _MarketSearch(
      marketSystems: marketSystems,
      marketSystemScores: marketSystemScores,
      claimedSystemSymbols: avoidSystems ?? {},
    );
  }

  final List<SystemRecord> marketSystems;
  final Map<SystemSymbol, int> marketSystemScores;
  final Set<SystemSymbol> claimedSystemSymbols;

  SystemRecord? closestAvailableSystem(SystemRecord startSystem) {
    final availableSystems =
        marketSystems
            .where((system) => !claimedSystemSymbols.contains(system.symbol))
            .toList();
    return _closestSystem(startSystem, availableSystems);
  }

  void markUsed(SystemRecord system) => claimedSystemSymbols.add(system.symbol);

  int scoreFor(SystemSymbol systemSymbol) => marketSystemScores[systemSymbol]!;
}
