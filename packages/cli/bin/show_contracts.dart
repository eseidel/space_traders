import 'package:args/args.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:types/types.dart';

void printContracts(
  String label,
  List<Contract> contracts,
  MarketPrices marketPrices, {
  required bool describeContracts,
}) {
  if (contracts.isEmpty) {
    return;
  }
  final punctuation = describeContracts ? ':' : '.';
  logger.info('${contracts.length} $label$punctuation');
  if (!describeContracts) {
    return;
  }
  for (final contract in contracts) {
    logger
      ..info(contractDescription(contract))
      ..info(describeExpectedContractProfit(marketPrices, contract));
  }
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final printAll = argResults['all'] as bool;
  final contractCache = ContractCache.loadCached(fs)!;
  final marketPrices = MarketPrices.load(fs);
  printContracts(
    'completed',
    contractCache.completedContracts,
    marketPrices,
    describeContracts: printAll,
  );
  printContracts(
    'expired',
    contractCache.expiredContracts,
    marketPrices,
    describeContracts: printAll,
  );
  printContracts(
    'active',
    contractCache.activeContracts,
    marketPrices,
    describeContracts: true,
  );
  printContracts(
    'unaccepted',
    contractCache.unacceptedContracts,
    marketPrices,
    describeContracts: true,
  );
}

void main(List<String> args) async {
  await runOfflineArgs(args, command, (parser) {
    parser.addFlag(
      'all',
      abbr: 'a',
      help: 'Print all contracts, not just active ones.',
      negatable: false,
    );
  });
}
