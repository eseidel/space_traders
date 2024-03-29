import 'package:cli/cache/market_price_snapshot.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/market_scores.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final topTen = scoreMarketSystems(marketPrices, limit: 10);
  for (final entry in topTen.entries) {
    final market = entry.key;
    final score = entry.value;
    logger.info('$market: $score');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
