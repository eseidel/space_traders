import 'package:cli/api.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:file/file.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditChange} ${t.accounting}';
}

Future<void> command(FileSystem fs, List<String> args) async {
  final shipNumber = args.firstOrNull;
  final shipId = ShipSymbol.fromString('ESEIDEL-$shipNumber');

  final lookbackMinutes = (args.length > 1) ? int.parse(args[1]) : 180;
  final lookback = Duration(minutes: lookbackMinutes);

  final transactionLog = await TransactionLog.load(fs);

  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = transactionLog.where(
    (t) => t.timestamp.isAfter(startTime) && t.shipSymbol == shipId.symbol,
  );
  for (final transaction in transactions) {
    logger.info(describeTransaction(transaction));
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}