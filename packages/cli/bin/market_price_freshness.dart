import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:stats/stats.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final prices = MarketPrices.load(fs);
  logger.info('${prices.count} prices loaded.');

  final now = DateTime.timestamp();
  final baseStats = Stats.fromData(
    prices.prices.map((p) => now.difference(p.timestamp).inSeconds),
  );
  final s = baseStats.withPrecision(3);
  String d(num seconds) =>
      approximateDuration(Duration(seconds: seconds.toInt()));
  logger.info('freshness: {average: ${d(s.average)}, '
      'median: ${d(s.median)}, '
      'min: ${d(s.min)}, '
      'max: ${d(s.max)}, '
      'stddev: ${d(s.standardDeviation)}}');
}

void main(List<String> args) {
  runOffline(args, command);
}