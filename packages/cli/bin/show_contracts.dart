import 'package:cli/api.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

int? expectedProfit(Contract contract, MarketPrices marketPrices) {
  // Add up the total expected outlay.
  final terms = contract.terms;
  final tradeSymbols = terms.deliver.map((d) => d.tradeSymbolObject).toSet();
  final medianPricesBySymbol = <TradeSymbol, int>{};
  for (final tradeSymbol in tradeSymbols) {
    final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol);
    if (medianPrice == null) {
      return null;
    }
    medianPricesBySymbol[tradeSymbol] = medianPrice;
  }

  final expectedOutlay = terms.deliver
      .map(
        (d) => medianPricesBySymbol[d.tradeSymbolObject]! * d.unitsRequired,
      )
      .fold(0, (sum, e) => sum + e);
  final payment = contract.terms.payment;
  final reward = payment.onAccepted + payment.onFulfilled;
  return reward - expectedOutlay;
}

String describeExpectedProfit(MarketPrices marketPrices, Contract contract) {
  final profit = expectedProfit(contract, marketPrices);
  final profitString = profit == null ? 'unknown' : creditsString(profit);
  return 'Expected profit: $profitString';
}

Future<void> command(FileSystem fs, List<String> args) async {
  final contractCache = ContractCache.loadCached(fs)!;
  final marketPrices = MarketPrices.load(fs);
  final completed = contractCache.completedContracts;
  if (completed.isNotEmpty) {
    logger.info('${completed.length} completed.');
  }
  final expired = contractCache.expiredContracts;
  if (expired.isNotEmpty) {
    logger.info('${expired.length} expired.');
  }
  final active = contractCache.activeContracts;
  if (active.isNotEmpty) {
    logger.info('${active.length} active:');
    for (final contract in active) {
      logger
        ..info(contractDescription(contract))
        ..info(describeExpectedProfit(marketPrices, contract));
    }
  }
  final unaccepted = contractCache.unacceptedContracts;
  if (unaccepted.isNotEmpty) {
    logger.info('${unaccepted.length} unaccepted:');
    for (final contract in unaccepted) {
      logger
        ..info(contractDescription(contract))
        ..info(describeExpectedProfit(marketPrices, contract));
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
