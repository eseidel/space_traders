import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:db/transaction.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditsChange}';
}

void reconcile(List<Transaction> transactions) {
  final startingCredits = transactions.first.agentCredits;
  var credits = startingCredits;
  // Skip the first transaction, since agentCredits already includes the
  // credits change from that transaction.
  for (final t in transactions.skip(1)) {
    credits += t.creditsChange;
    if (credits != t.agentCredits) {
      logger
        ..warn('Credits $credits does not match '
            'agentCredits ${t.agentCredits} ')
        ..info(describeTransaction(t));
      credits = t.agentCredits;
    }
  }
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  const lookback = Duration(minutes: 10);
  final db = await defaultDatabase();
  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = (await transactionsAfter(db, startTime)).toList();

  final lastCredits = transactions.last.agentCredits;
  final firstCredits = transactions.first.agentCredits;
  final creditDiff = lastCredits - firstCredits;
  final diffSign = creditDiff.isNegative ? '' : '+';
  logger.info(
    '$diffSign${creditsString(creditDiff)} '
    'over ${approximateDuration(lookback)} '
    'now ${creditsString(lastCredits)}',
  );
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
  final counts = <AccountingType, int>{};
  for (final t in transactions) {
    counts[t.accounting] = (counts[t.accounting] ?? 0) + 1;
  }
  for (final type in AccountingType.values) {
    final count = counts[type] ?? 0;
    logger.info('$count $type');
  }

  // Print the counts by transaction type.
  final transactionCounts = <TransactionType, int>{};
  for (final t in transactions) {
    transactionCounts[t.transactionType] =
        (transactionCounts[t.transactionType] ?? 0) + 1;
  }
  for (final type in TransactionType.values) {
    final count = transactionCounts[type] ?? 0;
    logger.info('$count $type');
  }

  await db.close();
}

void main(List<String> args) {
  runOffline(args, command);
}
