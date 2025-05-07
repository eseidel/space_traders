import 'package:cli/cli.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditsChange} ${t.accounting}';
}

Future<void> command(Database db, ArgResults argResults) async {
  final args = argResults.rest;
  final shipNumber = args.firstOrNull;
  final shipSymbol = ShipSymbol.fromString('ESEIDEL-$shipNumber');

  final lookbackMinutes = (args.length > 1) ? int.parse(args[1]) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = (await db.transactions.after(
    startTime,
  )).where((t) => t.shipSymbol == shipSymbol);
  for (final transaction in transactions) {
    logger.info(describeTransaction(transaction));
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
