import 'package:file/local.dart';
import 'package:scoped/scoped.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';

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

class ShipId implements Comparable<ShipId> {
  ShipId(this.name, this.number);

  ShipId.fromSymbol(String symbol)
      : name = symbol.split('-')[0],
        number = int.parse(symbol.split('-')[1], radix: 16);

  final String name;
  final int number;

  String get hexNumber => number.toRadixString(16).toUpperCase();
  String get symbol => '$name-$hexNumber';

  @override
  int compareTo(ShipId other) {
    final nameCompare = name.compareTo(other.name);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return number.compareTo(other.number);
  }

  @override
  String toString() => symbol;
}

Future<void> cliMain(List<String> args) async {
  // For a given ship, show the credits per minute averaged over the
  // last hour.
  final lookbackMinutesString = args.firstOrNull;
  final lookbackMinutes =
      lookbackMinutesString != null ? int.parse(lookbackMinutesString) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  const fs = LocalFileSystem();
  final transactions = await TransactionLog.load(fs);
  final shipSymbols = transactions.shipSymbols;
  final shipIds = shipSymbols.map(ShipId.fromSymbol).toList()..sort();

  final longestHexNumber = shipIds.fold(
    0,
    (m, s) => m > s.hexNumber.length ? m : s.hexNumber.length,
  );

  logger.info('Credits per minute for ships over the '
      'last ${approximateDuration(lookback)}:');

  for (final shipId in shipIds) {
    final perMinuteDiff = creditsPerMinute(
      transactions,
      shipId.symbol,
      lookback,
      filter: (t) => !t.tradeSymbol.startsWith('SHIP_'),
    );
    logger.info(
      '${shipId.hexNumber.padRight(longestHexNumber)}  '
      '${perMinuteDiff.toStringAsFixed(2)}',
    );
  }
}

void main(List<String> args) async {
  await runScoped(() => cliMain(args), values: {loggerRef});
}
