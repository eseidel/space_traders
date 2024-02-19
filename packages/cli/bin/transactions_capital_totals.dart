import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditsChange} ${t.accounting}';
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final transactions =
      await db.transactionsWithAccountingType(AccountingType.capital);

  final grouped = <String, List<Transaction>>{};
  for (final transaction in transactions) {
    final itemName =
        transaction.tradeSymbol?.value ?? transaction.shipType?.value ?? '???';
    grouped[itemName] = [...grouped[itemName] ?? [], transaction];
  }

  final names = grouped.keys.toList()..sort();
  final nameLength = names.map((n) => n.length).max;

  for (final name in names) {
    final transactions = grouped[name]!;
    final total = transactions.map((t) => t.creditsChange).sum;
    logger.info(
      '${name.padRight(nameLength)} '
      '${creditsString(total)} (${transactions.length})',
    );
    if (name == '???') {
      for (final transaction in transactions) {
        logger.info('  ${describeTransaction(transaction)}');
      }
    }
  }

  final total = transactions.map((t) => t.creditsChange).sum;
  logger.info('Total: ${creditsString(total)}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
