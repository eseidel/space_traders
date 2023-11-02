import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final tradeGoods = TradeGoodCache.load(fs);
  final marketListings = MarketListingCache.load(fs, tradeGoods);

  logger.info(
    'Loaded ${marketPrices.count} prices from '
    '${marketPrices.waypointCount} waypoints.',
  );

  marketListings.fillFromPrices(marketPrices);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
