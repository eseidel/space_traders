import 'package:cli/cli.dart';
import 'package:collection/collection.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditsChange}';
}

class SyntheticDeal {
  const SyntheticDeal(this.transactions);
  final List<Transaction> transactions;

  List<Transaction> get goodsBuys =>
      transactions
          .where(
            (t) =>
                t.tradeType == MarketTransactionTypeEnum.PURCHASE &&
                t.accounting == AccountingType.goods,
          )
          .toList();

  List<Transaction> get goodsSells =>
      transactions
          .where(
            (t) =>
                t.tradeType == MarketTransactionTypeEnum.SELL &&
                t.accounting == AccountingType.goods,
          )
          .toList();

  bool get isCompleted {
    final buys = goodsBuys;
    final sells = goodsSells;
    if (buys.isEmpty || sells.isEmpty) {
      return false;
    }
    return buys.length == sells.length;
  }

  TradeSymbol get tradeSymbol => goodsBuys.first.tradeSymbol!;

  int get units => goodsBuys.fold<int>(0, (sum, t) => sum + t.quantity);

  int get costOfGoodsSold =>
      goodsBuys.fold<int>(0, (sum, t) => sum + t.creditsChange);

  int get revenue => transactions
      .where((t) => t.tradeType == MarketTransactionTypeEnum.SELL)
      .fold<int>(0, (sum, t) => sum + t.creditsChange);

  int get operatingExpenses => transactions
      .where(
        (t) =>
            t.tradeType == MarketTransactionTypeEnum.PURCHASE &&
            t.accounting == AccountingType.fuel,
      )
      .fold<int>(0, (sum, t) => sum + t.creditsChange);

  int get profit => revenue + costOfGoodsSold + operatingExpenses;

  Duration get duration =>
      transactions.last.timestamp.difference(transactions.first.timestamp);

  int get profitPerSecond {
    final seconds = duration.inSeconds;
    if (seconds == 0) {
      logger
        ..warn('Broken: $isCompleted $duration $transactions')
        ..info(transactions.toString());
      return 0;
    }
    return profit ~/ duration.inSeconds;
  }

  ShipSymbol get shipSymbol => transactions.first.shipSymbol;

  WaypointSymbol get start => transactions.first.waypointSymbol;
  WaypointSymbol get end => transactions.last.waypointSymbol;
}

void printSyntheticDeal(SyntheticDeal deal) {
  logger.info(
    '${deal.shipSymbol} ${deal.units} of ${deal.tradeSymbol} '
    '${deal.start} -> ${deal.end} in ${approximateDuration(deal.duration)} '
    'for ${creditsString(deal.profit)} '
    '(${creditsString(deal.profitPerSecond)}/s)',
  );
}

bool Function(Transaction t) filterFromArgs(List<String> args) {
  final shipHex = args.firstOrNull;
  if (shipHex == null) {
    return (Transaction t) => true;
  }
  final shipSymbol = ShipSymbol.fromString('ESEIDEL-$shipHex');
  return (Transaction t) => t.shipSymbol == shipSymbol;
}

Future<void> command(Database db, ArgResults argResults) async {
  final filter = filterFromArgs(argResults.rest);
  final deals = <SyntheticDeal>[];
  final openDeals = <ShipSymbol, List<Transaction>>{};
  final ignoredTransactions = <Transaction>[];
  final supportedTypes = {AccountingType.fuel, AccountingType.goods};
  final transactions = await db.allTransactions();

  void recordDeal(List<Transaction> openDeal) {
    final deal = SyntheticDeal(openDeal);
    if (deal.isCompleted) {
      deals.add(deal);
    } else {
      ignoredTransactions.addAll(openDeal);
    }
  }

  for (final transaction in transactions) {
    if (!filter(transaction)) {
      continue;
    }
    // We only handle market transactions for now.
    if (transaction.tradeSymbol == null) {
      continue;
    }
    if (!supportedTypes.contains(transaction.accounting)) {
      ignoredTransactions.add(transaction);
      continue;
    }
    if (transaction.tradeType == MarketTransactionTypeEnum.PURCHASE &&
        transaction.accounting == AccountingType.goods) {
      final openDeal = openDeals[transaction.shipSymbol];
      if (openDeal == null) {
        openDeals[transaction.shipSymbol] = [transaction];
      } else if (openDeal.last.tradeType ==
          MarketTransactionTypeEnum.PURCHASE) {
        openDeal.add(transaction);
      } else {
        recordDeal(openDeal);
        openDeals[transaction.shipSymbol] = [transaction];
      }
    } else if (transaction.tradeType == MarketTransactionTypeEnum.SELL ||
        transaction.accounting == AccountingType.fuel) {
      final openDeal = openDeals[transaction.shipSymbol];
      if (openDeal == null) {
        ignoredTransactions.add(transaction);
        continue; // Ignore the transaction we don't have a purchase for.
      } else {
        openDeal.add(transaction);
      }
    }
  }
  for (final openDeal in openDeals.values) {
    recordDeal(openDeal);
  }

  final sorted = deals.sortedBy<num>((d) => d.profitPerSecond);

  logger.info('Worst 10:');
  final top = sorted.take(10);
  for (final deal in top) {
    printSyntheticDeal(deal);
  }

  logger.info('Best 20:');
  final bottom = sorted.reversed.take(20);
  for (final deal in bottom) {
    printSyntheticDeal(deal);
  }

  // for (final deal in deals) {
  //   printSyntheticDeal(deal);
  // }

  logger.info('Ignored ${ignoredTransactions.length} transactions.');
  // for (final transaction in ignoredTransactions) {
  //   logger.info(describeTransaction(transaction));
  // }
}
