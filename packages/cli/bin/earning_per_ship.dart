import 'package:cli/cache/behavior_snapshot.dart';
import 'package:cli/cache/ship_snapshot.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli_table/cli_table.dart';
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

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // For a given ship, show the credits per minute averaged over the
  // last hour.
  final lookbackMinutesString = argResults.rest.firstOrNull;
  final lookbackMinutes =
      lookbackMinutesString != null ? int.parse(lookbackMinutesString) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final shipSymbols = (await db.uniqueShipSymbolsInTransactions()).toList()
    ..sort();

  final ships = await ShipSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);
  final idleHaulers = behaviors.idleHaulerSymbols(ships);
  logger
    ..info('Fleet: ${describeShips(ships.ships)}')
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
  final frameCounts = <ShipFrameSymbolEnum, int>{};
  final frameCreditPerSecondTotals = <ShipFrameSymbolEnum, double>{};

  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = (await db.transactionsAfter(startTime)).where(
    (t) => [AccountingType.goods, AccountingType.fuel].contains(t.accounting),
  );

  final table = Table(
    header: [
      'Ship',
      'c/m',
      'c/s',
      'Role',
      'Txns',
      'Cargo',
    ],
    style: const TableStyle(compact: true),
  );

  Map<String, dynamic> rightAlign(Object? content) => <String, dynamic>{
        'content': content.toString(),
        'hAlign': HorizontalAlign.right,
      };

  for (final shipSymbol in shipSymbols) {
    final ship = ships[shipSymbol];
    final role = ship.fleetRole;
    final summary = TransactionSummary(
      transactions.where((t) => t.shipSymbol == shipSymbol),
    );
    roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    roleCreditPerSecondTotals[role] =
        (roleCreditPerSecondTotals[role] ?? 0) + summary.perSecond;

    frameCounts[ship.frame.symbol] = (frameCounts[ship.frame.symbol] ?? 0) + 1;
    frameCreditPerSecondTotals[ship.frame.symbol] =
        (frameCreditPerSecondTotals[ship.frame.symbol] ?? 0) +
            summary.perSecond;

    table.add([
      shipSymbol.hexNumber,
      rightAlign(c(summary.perMinute)),
      rightAlign(c(summary.perSecond)),
      role.name,
      summary.transactions.length,
      ship.cargo.capacity,
    ]);
  }
  logger
    ..info(table.toString())
    ..info('By role:');
  final sortedRoles = roleCounts.keys.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  for (final role in sortedRoles) {
    final count = roleCounts[role]!;
    final total = roleCreditPerSecondTotals[role]!;
    final average = (total / count).round();
    logger.info('${role.name.padRight(9)} '
        '${count.toString().padLeft(2)} ships '
        '${c(average).padLeft(3)} c/s');
  }
  logger.info('By frame:');
  final sortedFrames = frameCounts.keys.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (final frame in sortedFrames) {
    final count = frameCounts[frame]!;
    final total = frameCreditPerSecondTotals[frame]!;
    final average = (total / count).round();
    logger.info('${frame.value.padRight(9)} '
        '${count.toString().padLeft(2)} ships '
        '${c(average).padLeft(3)} c/s');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
