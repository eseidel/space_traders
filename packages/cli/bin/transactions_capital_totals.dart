import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';
import 'package:db/transaction.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditsChange} ${t.accounting}';
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final transactions =
      await transactionsWithAccountingType(db, AccountingType.capital);

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

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}