import 'package:cli/api.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';
import 'package:intl/intl.dart';

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
  final behaviorCache = BehaviorCache.load(fs);

  final longestHexNumber = shipIds.fold(
    0,
    (m, s) => m > s.hexNumber.length ? m : s.hexNumber.length,
  );

  final shipCache = ShipCache.loadCached(fs)!;
  final idleHaulers = idleHaulerSymbols(shipCache, behaviorCache);
  logger
    ..info(describeFleet(shipCache))
    ..info('${idleHaulers.length} idle traders')
    ..info('Credits per minute for ships over the '
        'last ${approximateDuration(lookback)}:');

  String c(num n) =>
      n.isFinite ? NumberFormat().format(n.round()) : n.toString();

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
        '${c(perMinuteDiff).padLeft(5)} c/m '
        '${c(perSecDiff).padLeft(4)} c/s '
        '  ${state?.behavior.name ?? 'Unknown'}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
