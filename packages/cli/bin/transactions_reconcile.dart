import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditsChange}';
}

void reconcile(List<Transaction> transactions) {
  final startingCredits = transactions.first.agentCredits;
  var credits = startingCredits;
  // Skip the first transaction, since agentCredits already includes the
  // credits change from that transaction.
  final toReconcile = transactions.skip(1).toList();
  for (var i = 0; i < toReconcile.length; i++) {
    final t = toReconcile[i];
    credits += t.creditsChange;
    final diff = credits - t.agentCredits;
    if (diff != 0) {
      logger
        ..warn('Computed ${creditsString(credits)} differs $diff from '
            'agentCredits ${t.agentCredits}')
        ..info('Before: ${describeTransaction(toReconcile[i - 1])}')
        ..info('After: ${describeTransaction(t)}');
      credits = t.agentCredits;
    }
  }
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final lookbackMinutesString = argResults.rest.firstOrNull;
  final lookbackMinutes =
      lookbackMinutesString != null ? int.parse(lookbackMinutesString) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = (await db.transactionsAfter(startTime)).toList();

  final lastCredits = transactions.last.agentCredits;
  final firstCredits = transactions.first.agentCredits;
  final creditDiff = lastCredits - firstCredits;
  final diffSign = creditDiff.isNegative ? '' : '+';
  logger
    ..info('Lookback ${approximateDuration(lookback)}')
    ..info('$diffSign${creditsString(creditDiff)}')
    ..info('now ${creditsString(lastCredits)}');
  final transactionCount = transactions.length;
  logger.info('$transactionCount transactions');

  // Add up the credits change from all transactions.
  // The diff should not include the first transaction, since agentCredits
  // is the credits *after* that transaction occured.
  final computedDiff =
      transactions.skip(1).fold(0, (sum, t) => sum + t.creditsChange);
  if (computedDiff != creditDiff) {
    logger.warn(
      'Computed diff $computedDiff does not match '
      'actual diff $creditDiff',
    );
    reconcile(transactions);
  }
  // Print the counts by accounting type.
  logger.info('By accounting:');
  final counts = <AccountingType, int>{};
  final accNameLength = AccountingType.values
      .map((type) => type.name.length)
      .reduce((a, b) => a > b ? a : b);
  for (final t in transactions) {
    counts[t.accounting] = (counts[t.accounting] ?? 0) + 1;
  }
  for (final type in AccountingType.values) {
    final count = counts[type] ?? 0;
    if (count == 0) continue;
    logger.info('  ${type.name.padRight(accNameLength)} $count');
  }

  // Print the counts by transaction type.
  logger.info('By transaction:');
  final transactionCounts = <TransactionType, int>{};
  final transNameLength = AccountingType.values
      .map((type) => type.name.length)
      .reduce((a, b) => a > b ? a : b);
  for (final t in transactions) {
    transactionCounts[t.transactionType] =
        (transactionCounts[t.transactionType] ?? 0) + 1;
  }
  for (final type in TransactionType.values) {
    final count = transactionCounts[type] ?? 0;
    if (count == 0) continue;
    logger.info('  ${type.name.padRight(transNameLength)} $count');
  }
}

void main(List<String> args) {
  runOffline(args, command);
}
