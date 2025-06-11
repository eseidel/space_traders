import 'package:cli/cli.dart';
import 'package:stats/stats.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // TODO(eseidel): This entire command could be a db query.
  final prices = await db.marketPrices.snapshotAll();
  logger.info('${prices.prices.length} prices loaded.');

  final now = DateTime.timestamp();
  final baseStats = Stats.fromData(
    prices.prices.map((p) => now.difference(p.timestamp).inSeconds),
  );
  final s = baseStats.withPrecision(3);
  String d(num seconds) =>
      approximateDuration(Duration(seconds: seconds.toInt()));
  logger.info(
    'freshness: {average: ${d(s.mean)}, '
    'median: ${d(s.median)}, '
    'min: ${d(s.min)}, '
    'max: ${d(s.max)}, '
    'stddev: ${d(s.standardDeviation)}}',
  );
}

void main(List<String> args) {
  runOffline(args, command);
}
