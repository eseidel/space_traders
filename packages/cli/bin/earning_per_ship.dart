import 'dart:math';

import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:db/transaction.dart';
import 'package:intl/intl.dart';

class TransactionSummary {
  TransactionSummary(Iterable<Transaction> transactions)
      : transactions = List.from(transactions);
  final List<Transaction> transactions;

  bool get isEmpty => transactions.isEmpty;

  int get creditDiff => transactions.fold(0, (m, t) => m + t.creditsChange);
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

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // For a given ship, show the credits per minute averaged over the
  // last hour.
  final lookbackMinutesString = argResults.rest.firstOrNull;
  final lookbackMinutes =
      lookbackMinutesString != null ? int.parse(lookbackMinutesString) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final db = await defaultDatabase();

  final shipSymbols = (await uniqueShipSymbolsInTransactions(db)).toList()
    ..sort();
  final behaviorCache = BehaviorCache.load(fs);

  final longestHexNumber =
      shipSymbols.map((s) => s.hexNumber.length).reduce(max);

  final shipCache = ShipCache.loadCached(fs)!;
  final idleHaulers = idleHaulerSymbols(shipCache, behaviorCache);
  logger
    ..info(describeFleet(shipCache))
    ..info('${idleHaulers.length} idle traders')
    ..info('Credits per minute for ships over the '
        'last ${approximateDuration(lookback)}:');

  String c(num? n) {
    if (n == null) return '';
    if (!n.isFinite) return n.toString();
    return NumberFormat().format(n.round());
  }

  final roleCounts = <FleetRole, int>{};
  final roleCreditPerSecondTotals = <FleetRole, double>{};

  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = (await transactionsAfter(db, startTime)).where(
    (t) => [AccountingType.goods, AccountingType.fuel].contains(t.accounting),
  );

  for (final shipSymbol in shipSymbols) {
    final ship = shipCache.ship(shipSymbol);
    if (ship.isProbe) {
      continue;
    }
    final role = ship.fleetRole;
    final summary = TransactionSummary(
      transactions.where((t) => t.shipSymbol == shipSymbol),
    );
    roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    roleCreditPerSecondTotals[role] =
        (roleCreditPerSecondTotals[role] ?? 0) + summary.perSecond;
    logger.info('${shipSymbol.hexNumber.padRight(longestHexNumber)}  '
        '${c(summary.perMinute).padLeft(5)} c/m '
        '${c(summary.perSecond).padLeft(4)} c/s '
        '${role.name.padRight(10)}');
  }
  final sortedRoles = roleCounts.keys.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  for (final role in sortedRoles) {
    final count = roleCounts[role]!;
    final total = roleCreditPerSecondTotals[role]!;
    final average = (total / count).round();
    logger.info('${role.name}: $count ships, ${c(average)} c/s');
  }
  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
