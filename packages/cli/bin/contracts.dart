import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/contract_snapshot.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';

Future<void> printContracts(
  Database db,
  String label,
  List<Contract> contracts, {
  required bool describeContracts,
}) async {
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
      ..info(await describeExpectedContractProfit(db, contract));
  }
}

Future<void> command(Database db, ArgResults argResults) async {
  final printAll = argResults['all'] as bool;
  final contractSnapshot = await ContractSnapshot.load(db);
  await printContracts(
    db,
    'completed',
    contractSnapshot.completedContracts,
    describeContracts: printAll,
  );
  await printContracts(
    db,
    'expired',
    contractSnapshot.expiredContracts,
    describeContracts: printAll,
  );
  await printContracts(
    db,
    'active',
    contractSnapshot.activeContracts,
    describeContracts: true,
  );
  await printContracts(
    db,
    'unaccepted',
    contractSnapshot.unacceptedContracts,
    describeContracts: true,
  );
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
