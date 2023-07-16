import 'package:cli/api.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:file/file.dart';

String describeTransaction(Transaction t) {
  return '${t.timestamp} ${t.tradeSymbol} ${t.quantity} ${t.tradeType} '
      '${t.shipSymbol} ${t.waypointSymbol} ${t.creditChange}';
}

Future<void> command(FileSystem fs, List<String> args) async {
  final lookbackMinutesString = args.firstOrNull;
  final lookbackMinutes =
      lookbackMinutesString != null ? int.parse(lookbackMinutesString) : 180;
  final lookback = Duration(minutes: lookbackMinutes);
  final shipId = ShipSymbol.fromString('ESEIDEL-1');

  final transactionLog = await TransactionLog.load(fs);

  final startTime = DateTime.timestamp().subtract(lookback);
  final transactions = transactionLog.where(
    (t) =>
        t.timestamp.isAfter(startTime) &&
        t.shipSymbol == shipId.symbol &&
        !t.tradeSymbol.startsWith('SHIP_'),
  );
  for (final transaction in transactions) {
    logger.info(describeTransaction(transaction));
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
