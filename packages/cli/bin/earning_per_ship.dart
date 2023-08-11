import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:db/transaction.dart';
import 'package:intl/intl.dart';

class TransactionSummary {
  TransactionSummary(Iterable<Transaction> transactions)
      : transactions = List.from(transactions);
  final List<Transaction> transactions;

  bool get isEmpty => transactions.isEmpty;

  int get creditDiff => transactions.fold(0, (m, t) => m + t.creditChange);
  Duration get duration => transactions.isEmpty
      ? Duration.zero
      : transactions.last.timestamp.difference(transactions.first.timestamp);

  double get perSecond {
    if (duration.inSeconds == 0) {
      return 0;
    }
    return creditDiff / duration.inSeconds;
  }

  double? get perMinute {
    if (duration > const Duration(minutes: 1)) {
      return creditDiff / duration.inMinutes;
    } else {
      return null;
    }
  }

  double? get perHour {
    if (duration > const Duration(hours: 1)) {
      return creditDiff / duration.inHours;
    } else {
      return null;
    }
  }
}

Behavior? behaviorFromFrame(Ship ship) {
  return {
    ShipFrameSymbolEnum.PROBE: Behavior.explorer,
    ShipFrameSymbolEnum.MINER: Behavior.miner,
    ShipFrameSymbolEnum.LIGHT_FREIGHTER: Behavior.trader,
  }[ship.frame.symbol];
}

Future<void> command(FileSystem fs, List<String> args) async {
  // For a given ship, show the credits per minute averaged over the
  // last hour.
  final lookbackMinutesString = args.firstOrNull;
  final lookbackMinutes =
      lookbackMinutesString != null ? int.parse(lookbackMinutesString) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final db = await defaultDatabase();

  final shipSymbols = (await uniqueShipSymbols(db)).map(ShipSymbol.fromString);
  final behaviorCache = BehaviorCache.load(fs);

  final longestHexNumber = shipSymbols.fold(
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

  String c(num? n) {
    if (n == null) {
      return '';
    }
    return n.isFinite ? NumberFormat().format(n.round()) : n.toString();
  }

  final behaviorCounts = <String, int>{};
  final behaviorCreditPerSecondTotals = <String, double>{};

  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = (await transactionsAfter(db, startTime))
      .map(Transaction.fromRecord)
      .where(
        (t) =>
            t.accounting == AccountingType.goods ||
            t.accounting == AccountingType.fuel,
      );

  for (final shipSymbol in shipSymbols) {
    final ship = shipCache.ship(shipSymbol);
    final state = behaviorCache.getBehavior(shipSymbol);
    if (ship.isProbe) {
      continue;
    }
    final stateName =
        state?.behavior.name ?? behaviorFromFrame(ship)?.name ?? 'Unknown';
    final summary = TransactionSummary(
      transactions.where((t) => t.shipSymbol == shipSymbol),
    );
    behaviorCounts[stateName] = (behaviorCounts[stateName] ?? 0) + 1;
    behaviorCreditPerSecondTotals[stateName] =
        (behaviorCreditPerSecondTotals[stateName] ?? 0) + summary.perSecond;
    logger.info('${shipSymbol.hexNumber.padRight(longestHexNumber)}  '
        '${c(summary.perMinute).padLeft(5)} c/m '
        '${c(summary.perSecond).padLeft(4)} c/s '
        '  ${stateName.padRight(10)}');
  }
  for (final stateName in behaviorCounts.keys.toList()..sort()) {
    final count = behaviorCounts[stateName]!;
    final total = behaviorCreditPerSecondTotals[stateName]!;
    final average = (total / count).round();
    logger.info('$stateName: $count ships, ${c(average)} c/s');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
