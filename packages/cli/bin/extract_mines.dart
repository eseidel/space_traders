import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/mine_scores.dart';
import 'package:cli/net/auth.dart';
import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';

/// Given a set of trade symbols, compute the percentage sell price
/// across the set.
double _scoreMarket(
  MarketPrices marketPrices,
  WaypointSymbol marketSymbol,
  Set<TradeSymbol> symbols,
) {
  // Walk the prices for the given symbols at the given market, and compute
  // the average percentage sell price relative to global median sell prices.
  final percentiles = symbols.map((tradeSymbol) {
    final sellPrice =
        marketPrices.recentSellPrice(tradeSymbol, marketSymbol: marketSymbol);
    if (sellPrice == null) {
      return 0.0;
    }
    final percentile =
        marketPrices.percentileForSellPrice(tradeSymbol, sellPrice);
    if (percentile == null) {
      return 0.0;
    }
    return percentile;
  }).toList();
  return percentiles.average / 100.0;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final countLimit = int.tryParse(argResults['limit'] as String);
  if (countLimit == null) {
    throw ArgumentError.value(
      argResults['limit'],
      'limit',
      'Must be an integer.',
    );
  }

  final maxDistance = int.tryParse(argResults['max-distance'] as String);
  if (maxDistance == null) {
    throw ArgumentError.value(
      argResults['max-distance'],
      'max-distance',
      'Must be an integer.',
    );
  }

  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => 0);
  final systems = await SystemsCache.loadOrFetch(fs);
  final waypointTraits = WaypointTraitCache.load(fs);
  final charting = ChartingCache.load(fs, waypointTraits);
  final construction = ConstructionCache.load(fs);
  final waypointCache = WaypointCache(api, systems, charting, construction);
  final agentCache = AgentCache.load(fs)!;
  final hqSystem = agentCache.headquartersSystemSymbol;
  final tradeGoods = TradeGoodCache.load(fs);
  final marketListings = MarketListingCache.load(fs, tradeGoods);
  final marketPrices = MarketPrices.load(fs);

  final scores =
      await evaluateWaypointsForMining(waypointCache, marketListings, hqSystem);

  final table = Table(
    header: ['Mine', 'Traits', 'Market', 'Distance', 'Goods', 'Market Score'],
    style: const TableStyle(compact: true),
  );

  // Limit to only the closest for each.
  final seenMines = <WaypointSymbol>{};
  for (final score in scores) {
    if (seenMines.contains(score.mine)) {
      continue;
    }
    // Only consider markets that trade all goods produced by the mine.
    if (!score.marketTradesAllProducedGoods) {
      // If the market doesn't trade any goods from the mine, don't even
      // bother logging.
      if (score.goodsMissingFromMarket.length != score.producedGoods.length) {
        logger.detail(
            '${score.market} does not trade ${score.goodsMissingFromMarket}'
            ' produced by ${score.mine}, only ${score.tradedGoods}.');
      }
      continue;
    }
    if (score.score > maxDistance) {
      logger.detail(
        '${score.mine} is too far (${score.score}) from ${score.market}',
      );
      continue;
    }
    // Should check mine too.
    if (!score.tradedGoods.contains(TradeSymbol.FUEL)) {
      logger
        ..warn('${score.market} does not trade fuel.')
        ..info('${score.market} trades ${score.producedGoods}');
      continue;
    }

    final marketScore = _scoreMarket(
      marketPrices,
      score.market,
      score.producedGoods,
    );

    seenMines.add(score.mine);
    table.add([
      score.mine.toString(),
      score.mineTraitNames.join(', '),
      score.market.toString(),
      score.score,
      score.producedGoods.join(', '),
      marketScore,
    ]);
    if (seenMines.length >= countLimit) {
      break;
    }
  }
  logger.info(table.toString());

  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (parser) {
      parser
        ..addOption(
          'limit',
          abbr: 'l',
          help: 'Limit the number of markets to look at.',
          defaultsTo: '10',
        )
        ..addOption(
          'max-distance',
          abbr: 'd',
          help: 'Limit the travel distance between the mine and market.',
          defaultsTo: '80',
        );
    },
  );
}
