import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:file/file.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final marketPrices = await MarketPrices.load(fs);
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
