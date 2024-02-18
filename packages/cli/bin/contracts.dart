import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

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
  final db = await defaultDatabase();
  final printAll = argResults['all'] as bool;
  final contractSnapshot = await ContractSnapshot.load(db);
  final marketPrices = await MarketPrices.load(db);
  printContracts(
    'completed',
    contractSnapshot.completedContracts,
    marketPrices,
    describeContracts: printAll,
  );
  printContracts(
    'expired',
    contractSnapshot.expiredContracts,
    marketPrices,
    describeContracts: printAll,
  );
  printContracts(
    'active',
    contractSnapshot.activeContracts,
    marketPrices,
    describeContracts: true,
  );
  printContracts(
    'unaccepted',
    contractSnapshot.unacceptedContracts,
    marketPrices,
    describeContracts: true,
  );

  await db.close();
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (ArgParser parser) {
      parser.addFlag(
        'all',
        abbr: 'a',
        help: 'Print all contracts, not just active ones.',
        negatable: false,
      );
    },
  );
}
