// import 'package:scidart/numdart.dart';

import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';

void printDiffs(List<int> data) {
  final diffs = <int>[];
  for (var i = 1; i < data.length; i++) {
    diffs.add(data[i] - data[i - 1]);
  }
  logger.info(diffs.toString());
}

Future<void> command(FileSystem fs, List<String> args) async {
  // final marketPrices = MarketPrices.load(fs);
  final transactionLogOld =
      TransactionLog.load(fs, path: 'data/transactions1.json');
  final transactionLog = TransactionLog.load(fs);
  final allTransactions =
      transactionLogOld.entries.followedBy(transactionLog.entries);

  // Walk through all transactions, finding repeats.
  final transactionSets = <List<Transaction>>[];
  var repeats = <Transaction>[];
  for (final transaction in allTransactions) {
    // If the transaction has the same market and tradeSymbol as the previous
    // one, then it's a repeat, and should be collected together into a group
    // of repeats.
    if (repeats.isNotEmpty &&
        repeats.last.waypointSymbol == transaction.waypointSymbol &&
        repeats.last.tradeSymbol == transaction.tradeSymbol &&
        repeats.last.tradeType == transaction.tradeType) {
      repeats.add(transaction);
    } else {
      // If the transaction is not a repeat, then we need to check if the
      // repeats we've collected so far are actually repeats.
      if (repeats.isNotEmpty) {
        // If the repeats are actually repeats, then we can add them to the
        // transactionSets.
        // Ignore sets smaller than 5.
        if (repeats.length > 4) {
          transactionSets.add(repeats);
        }
        // Either way, we need to clear the repeats list.
        repeats = [];
      }
      // Finally, we need to add the current transaction to the repeats list.
      repeats.add(transaction);
    }
  }
  for (final transactionSet in transactionSets) {
    final set = transactionSet;
    final transaction = set.first;
    logger.info(
      '${set.length} x ${transaction.tradeType} '
      '${transaction.tradeSymbol} '
      'at ${transaction.waypointSymbol}',
    );
    // Generate a list of the diffs in price between transactions.
    final diffs = <int>[];
    for (var i = 1; i < set.length; i++) {
      diffs.add(set[i].perUnitPrice - set[i - 1].perUnitPrice);
    }
    printDiffs(diffs);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
