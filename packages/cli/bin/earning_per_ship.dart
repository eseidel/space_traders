import 'package:cli/api.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

double creditsPerMinute(
  TransactionLog transactions,
  String shipSymbol,
  Duration lookback, {
  bool Function(Transaction t)? filter,
}) {
  final startTime = DateTime.timestamp().subtract(lookback);
  final shipTransactions = transactions.entries
      .where((t) => t.shipSymbol == shipSymbol)
      .where((t) => t.timestamp.isAfter(startTime))
      .toList();
  if (filter != null) {
    shipTransactions.retainWhere(filter);
  }

  final sorted = shipTransactions.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  if (sorted.isEmpty) {
    return 0;
  }

  final diff = sorted.fold(0, (m, t) => m + t.creditChange);
  final minutes =
      sorted.last.timestamp.difference(sorted.first.timestamp).inMinutes;
  return diff / minutes;
}

Future<void> command(FileSystem fs, List<String> args) async {
  // For a given ship, show the credits per minute averaged over the
  // last hour.
  final lookbackMinutesString = args.firstOrNull;
  final lookbackMinutes =
      lookbackMinutesString != null ? int.parse(lookbackMinutesString) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final transactions = await TransactionLog.load(fs);
  final shipSymbols = transactions.shipSymbols;
  final shipIds = shipSymbols.map(ShipSymbol.fromString).toList()..sort();
  final behaviorCache = await BehaviorCache.load(fs);

  final longestHexNumber = shipIds.fold(
    0,
    (m, s) => m > s.hexNumber.length ? m : s.hexNumber.length,
  );

  logger.info('Credits per minute for ships over the '
      'last ${approximateDuration(lookback)}:');

  for (final shipId in shipIds) {
    final state = behaviorCache.getBehavior(shipId.symbol);
    final perMinuteDiff = creditsPerMinute(
      transactions,
      shipId.symbol,
      lookback,
      filter: (t) => !t.tradeSymbol.startsWith('SHIP_'),
    );
    final perSecDiff = perMinuteDiff / 60;
    logger.info('${shipId.hexNumber.padRight(longestHexNumber)}  '
        '${creditsString(perMinuteDiff.round())}/min '
        '(${creditsString(perSecDiff.round())}/sec) '
        '  ${state?.behavior.name ?? 'Unknown'}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
