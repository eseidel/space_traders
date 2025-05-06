import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/market_price_snapshot.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/plan/extraction_score.dart';
import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';

/// Given a set of trade symbols, compute the percentage sell price
/// across the set.
double _scoreMarkets(
  MarketPriceSnapshot marketPrices,
  Map<TradeSymbol, WaypointSymbol> marketForGood,
) {
  // Walk the prices for the given symbols at the given market, and compute
  // the average percentage sell price relative to global median sell prices.
  final percentiles =
      marketForGood.keys.map((tradeSymbol) {
        final marketSymbol = marketForGood[tradeSymbol]!;
        final sellPrice = marketPrices.recentSellPrice(
          tradeSymbol,
          marketSymbol: marketSymbol,
        );
        if (sellPrice == null) {
          logger.warn('No sell price for $tradeSymbol at $marketSymbol');
          return 0.0;
        }
        final percentile = marketPrices.percentileForSellPrice(
          tradeSymbol,
          sellPrice,
        );
        if (percentile == null) {
          logger.warn('No percentile for $tradeSymbol at $marketSymbol');
          return 0.0;
        }
        return percentile;
      }).toList();
  return percentiles.average / 100.0;
}

Future<void> command(Database db, ArgResults argResults) async {
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

  final isSiphon = argResults['siphon'] as bool;

  logger.info(
    "Top $countLimit ${isSiphon ? 'siphon targets' : 'mines'}"
    ' with matching markets within $maxDistance total round-trip:',
  );

  final systems = await db.snapshotAllSystems();
  final charting = ChartingCache(db);
  final hqSystem = await myHqSystemSymbol(db);
  final marketPrices = await MarketPriceSnapshot.loadOneSystem(db, hqSystem);

  final List<ExtractionScore> scores;
  if (isSiphon) {
    scores = await evaluateWaypointsForSiphoning(
      db,
      systems,
      charting,
      hqSystem,
    );
  } else {
    scores = await evaluateWaypointsForMining(db, systems, charting, hqSystem);
  }

  final table = Table(
    header: ['Source', 'Source Traits', 'Markets', 'Dist', 'Goods', 'Score'],
    style: const TableStyle(compact: true),
  );

  // Limit to only the closest for each.
  final seenSources = <WaypointSymbol>{};
  for (final score in scores) {
    if (seenSources.contains(score.source)) {
      continue;
    }
    // Only consider markets that trade all goods produced by the mine.
    if (!score.marketsTradeAllProducedGoods) {
      logger.detail(
        'Could not find places to sell ${score.goodsMissingFromMarkets}'
        ' produced by ${score.source}.',
      );
      continue;
    }
    if (score.deliveryDistance > maxDistance) {
      logger.detail(
        '${score.source} is too far (${score.deliveryDistance}) from markets.',
      );
      continue;
    }
    // Check if route sells fuel at all?

    // Score each good at each market.
    final marketScore = _scoreMarkets(marketPrices, score.marketForGood);

    seenSources.add(score.source);
    table.add([
      score.source.waypointName,
      score.displayTraitNames.join(', '),
      score.markets.map((m) => m.waypointName).join(', '),
      score.score,
      score.producedGoods.join(', '),
      marketScore.toStringAsPrecision(2),
    ]);
    if (seenSources.length >= countLimit) {
      break;
    }
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (ArgParser parser) {
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
          help: 'Limit the round trip distance between the mine and markets.',
          defaultsTo: config.maxExtractionDeliveryDistance.toString(),
        )
        ..addFlag('siphon', help: 'Show siphons instead of mining.');
    },
  );
}
