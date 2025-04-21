import 'package:cli_client/cli_client.dart';
import 'package:client/client.dart';

Future<void> main(List<String> args) async {
  await runAsClient(args, command);
}

Future<void> command(BackendClient client, ArgResults argResults) async {
  final response = await client.getFleetInventory();
  for (final item in response.items) {
    final price = item.medianPrice;
    final count = item.count;
    final symbol = item.tradeSymbol;
    if (price == null) {
      logger.warn('No price for $symbol');
      continue;
    }
    final value = price * count;
    logger.info(
      '${symbol.value.padRight(23)} ${count.toString().padLeft(3)} x '
      '${creditsString(price).padRight(8)} = ${creditsString(value)}',
    );
  }
  logger.info('Total value: ${creditsString(response.totalValue)}');
}
