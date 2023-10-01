import 'package:cli/cli.dart';
import 'package:db/db.dart';
import 'package:db/transaction.dart';
import 'package:types/types.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditChange} ${t.accounting}';
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final args = argResults.rest;
  final shipNumber = args.firstOrNull;
  final shipSymbol = ShipSymbol.fromString('ESEIDEL-$shipNumber');

  final lookbackMinutes = (args.length > 1) ? int.parse(args[1]) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final db = await defaultDatabase();
  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = (await transactionsAfter(db, startTime))
      .where((t) => t.shipSymbol == shipSymbol);
  for (final transaction in transactions) {
    logger.info(describeTransaction(transaction));
  }
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
