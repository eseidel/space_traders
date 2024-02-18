import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/market_scores.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final marketPrices = await MarketPrices.load(db);
  final topTen = scoreMarketSystems(marketPrices, limit: 10);
  for (final entry in topTen.entries) {
    final market = entry.key;
    final score = entry.value;
    logger.info('$market: $score');
  }
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
