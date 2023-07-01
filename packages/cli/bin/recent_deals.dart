import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditChange}';
}

class SyntheticDeal {
  const SyntheticDeal(this.transactions);
  final List<Transaction> transactions;
}

void printSyntheticDeal(SyntheticDeal deal) {
  final entries = deal.transactions;
  final start = entries.first.waypointSymbol;
  final end = entries.last.waypointSymbol;
  final buyEntries = entries
      .where((t) => t.tradeType == MarketTransactionTypeEnum.PURCHASE)
      .toList();
  final sellEntries = entries
      .where((t) => t.tradeType == MarketTransactionTypeEnum.SELL)
      .toList();
  final buyUnits = buyEntries.fold<int>(0, (sum, t) => sum + t.quantity);
  final sellUnits = sellEntries.fold<int>(0, (sum, t) => sum + t.quantity);
  if (buyUnits != sellUnits) {
    return; // incomplete deal
  }
  final totalSpend = buyEntries.fold<int>(0, (sum, t) => sum + t.creditChange);
  final totalRevenue =
      sellEntries.fold<int>(0, (sum, t) => sum + t.creditChange);
  final profit = totalRevenue + totalSpend;
  final time = entries.last.timestamp.difference(entries.first.timestamp);
  final profitPerSecond = profit / time.inSeconds;
  final shipSymbol = entries.first.shipSymbol;

  logger.info('$shipSymbol $buyUnits of ${buyEntries.first.tradeSymbol} '
      '$start -> $end in ${approximateDuration(time)} '
      'for ${creditsString(profit)} '
      '(${creditsString(profitPerSecond.toInt())}/s)');
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final deals = <SyntheticDeal>[];
  final openDeals = <String, List<Transaction>>{};
  for (final transaction in caches.transactions.entries) {
    // Ignore fuel transactions for now, our logic below would need to be more
    // complicated not to get confused by them.
    if (transaction.tradeSymbol == TradeSymbol.FUEL.value) {
      continue;
    }
    if (transaction.tradeType == MarketTransactionTypeEnum.PURCHASE) {
      final openDeal = openDeals[transaction.shipSymbol];
      if (openDeal == null) {
        openDeals[transaction.shipSymbol] = [transaction];
      } else if (openDeal.last.tradeType ==
          MarketTransactionTypeEnum.PURCHASE) {
        openDeal.add(transaction);
      } else {
        deals.add(SyntheticDeal(openDeal));
        openDeals[transaction.shipSymbol] = [transaction];
      }
    } else if (transaction.tradeType == MarketTransactionTypeEnum.SELL) {
      final openDeal = openDeals[transaction.shipSymbol];
      if (openDeal == null) {
        continue; // Ignore the transaction we don't have a purchase for.
      } else {
        openDeal.add(transaction);
      }
    }
  }
  for (final openDeal in openDeals.values) {
    deals.add(SyntheticDeal(openDeal));
  }

  for (final deal in deals) {
    printSyntheticDeal(deal);
  }
}
