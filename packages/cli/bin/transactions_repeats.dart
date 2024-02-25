import 'package:cli/cli.dart';

void printDiffs(List<int> data) {
  final diffs = <int>[];
  for (var i = 1; i < data.length; i++) {
    diffs.add(data[i] - data[i - 1]);
  }
  logger.info(diffs.toString());
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final transactions = await db.allTransactions();
  // Walk through all transactions, finding repeats.
  final transactionSets = <List<Transaction>>[];
  var repeats = <Transaction>[];
  for (final transaction in transactions) {
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
    final tradeVolume = transaction.quantity; // actually the max across set.
    /// Ones not a multiple of 10 are just mining sales.
    if (tradeVolume % 10 != 0) {
      continue;
    }
    // Transaction.tradeSymbol isn't always a tradeSymbol (it could be a
    // shipSymbol) but repeated ones should always be TradeSymbols.
    // final tradeSymbol = TradeSymbol.fromJson(transaction.tradeSymbol)!;
    // final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
    logger.info(
      '${set.length} x ${transaction.tradeType} ($tradeVolume) '
      '${transaction.tradeSymbol} '
      'at ${transaction.waypointSymbol}',
    );
    // Generate a list of the diffs in price between transactions.
    final diffs = <int>[];
    for (var i = 1; i < set.length; i++) {
      diffs.add(set[i].perUnitPrice - set[i - 1].perUnitPrice);
    }
    printDiffs(diffs);

    final diffAsPercentOfCurrentPrice = <double>[];
    for (var i = 1; i < set.length; i++) {
      diffAsPercentOfCurrentPrice.add(
        (set[i].perUnitPrice - set[i - 1].perUnitPrice) /
            set[i].perUnitPrice *
            100,
      );
    }
    printDiffs(diffAsPercentOfCurrentPrice.map((e) => e.round()).toList());

    // final diffToMedian = <int>[];
    // for (var i = 1; i < set.length; i++) {
    //   diffToMedian.add(set[i].perUnitPrice - medianPrice);
    // }
    // printDiffs(diffToMedian);

    // final medianPercents = <double>[];
    // for (final diff in diffs) {
    //   medianPercents.add(diff / medianPrice);
    // }
    // printDiffs(medianPercents.map((e) => (e * 100).round()).toList());

    // final diffAsPercentOfMedianDiff = <double>[];
    // for (var i = 1; i < set.length; i++) {
    //   diffAsPercentOfMedianDiff.add(
    //     (set[i].perUnitPrice - set[i - 1].perUnitPrice) /
    //         (set[i].perUnitPrice - medianPrice),
    //   );
    // }
    // printDiffs(
    //   diffAsPercentOfMedianDiff.map((e) => (e * 100).round()).toList(),
    // );

    // const degree = 2;
    // final x = Array(
    //   List<double>.generate(
    //     set.length,
    //     (i) => i.toDouble() * tradeVolume,
    //   ),
    // );
    // final y = Array(set.map((t) => t.perUnitPrice / medianPrice).toList());
    // final p = PolyFit(x, y, degree);
    // print(p);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
