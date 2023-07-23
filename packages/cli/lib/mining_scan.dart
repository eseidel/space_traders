import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:collection/collection.dart';

/// Want to find systems which have both a mineable resource and a marketplace.
/// Want to sort by distance between the two.
/// As well as relative prices for the market.
/// Might also want to consider what resources the mine produces and if the
/// market buys them.

class _MineAndSell {
  _MineAndSell({
    required this.mineSymbol,
    required this.marketSymbol,
    required this.marketPercentile,
    required this.distanceBetweenMineAndMarket,
  });

  final WaypointSymbol mineSymbol;
  final WaypointSymbol marketSymbol;
  final int marketPercentile;
  final int distanceBetweenMineAndMarket;

  int get score {
    final creditsAboveAverage = marketPercentile - 50;
    final distancePenalty = distanceBetweenMineAndMarket;
    // The primary thing we care about is market percentile.
    // Distances other than 0 have a fuel cost associated with them.
    // Which would need to be made up by the market percentile?
    // Maybe this is just estimated profit per second?
    // Which then will be dominated by the presence of certain resources.
    return creditsAboveAverage - distancePenalty;
  }
}

class _SystemEval {
  _SystemEval({
    required this.systemSymbol,
    required this.jumps,
    required this.mineAndSells,
  });

  final SystemSymbol systemSymbol;
  final int jumps;
  final List<_MineAndSell> mineAndSells;

  int? get score {
    if (mineAndSells.isEmpty) {
      return null;
    }
    // This assumes these are sorted.
    return mineAndSells.last.score;
  }
}

int? _marketPercentile(
  MarketPrices marketPrices,
  Market market, {
  required TradeSymbol tradeSymbol,
}) {
  final sellPrice = estimateSellPrice(marketPrices, market, tradeSymbol);
  if (sellPrice == null) {
    return null;
  }
  return marketPrices.percentileForSellPrice(
    tradeSymbol,
    sellPrice,
  );
}

Future<_SystemEval> _evaluateSystem(
  Api api,
  MarketPrices marketPrices,
  WaypointCache waypointCache,
  MarketCache marketCache, {
  required TradeSymbol tradeSymbol,
  required SystemSymbol systemSymbol,
  required int jumps,
}) async {
  final waypoints = await waypointCache.waypointsInSystem(systemSymbol);
  final marketWaypoints = waypoints.where((w) => w.hasMarketplace);
  final markets = await marketCache.marketsInSystem(systemSymbol).toList();
  final marketToPercentile = {
    for (var m in markets)
      m.symbol: _marketPercentile(marketPrices, m, tradeSymbol: tradeSymbol),
  };
  final mines = waypoints.where((w) => w.canBeMined);
  final mineAndSells = <_MineAndSell>[];
  for (final mine in mines) {
    for (final market in marketWaypoints) {
      final marketPercentile = marketToPercentile[market.symbol];
      if (marketPercentile == null) {
        continue;
      }
      final distance = mine.distanceTo(market);
      mineAndSells.add(
        _MineAndSell(
          mineSymbol: mine.waypointSymbol,
          marketSymbol: market.waypointSymbol,
          marketPercentile: marketPercentile,
          distanceBetweenMineAndMarket: distance,
        ),
      );
    }
  }
  mineAndSells.sortBy<num>((m) => m.score);
  return _SystemEval(
    systemSymbol: systemSymbol,
    jumps: jumps,
    mineAndSells: mineAndSells,
  );
}

String _describeSystemEval(_SystemEval eval) {
  return '${eval.systemSymbol}: ${eval.jumps} jumps ${eval.score}';
}

/// Find nearest mine with good mining.
Future<WaypointSymbol?> nearestMineWithGoodMining(
  Api api,
  MarketPrices marketPrices,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  SystemWaypoint start, {
  required TradeSymbol tradeSymbol,
  required int maxJumps,
  bool Function(SystemSymbol systemSymbol)? systemFilter,
}) async {
  // TODO(eseidel): These evals should be cached on centralCommand.
  final evals = <_SystemEval>[];
  for (final (systemSymbol, jumps) in systemsCache.systemSymbolsInJumpRadius(
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    if (systemFilter != null && !systemFilter(systemSymbol)) {
      continue;
    }
    final eval = await _evaluateSystem(
      api,
      marketPrices,
      waypointCache,
      marketCache,
      tradeSymbol: tradeSymbol,
      systemSymbol: systemSymbol,
      jumps: jumps,
    );
    logger.info(
      _describeSystemEval(eval),
    );
    // Want to know if the market buys what the mine produces?
    if (eval.score != null) {
      evals.add(eval);
    }
  }
  final sorted = evals.sortedBy<num>((e) => e.score!);
  final best = sorted.lastOrNull;
  if (best == null) {
    return null;
  }
  return best.mineAndSells.last.mineSymbol;
}
