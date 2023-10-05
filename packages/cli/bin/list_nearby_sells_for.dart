import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/trading.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = SystemsCache.loadCached(fs)!;
  final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);
  final shipCache = ShipCache.loadCached(fs)!;

  final ship = shipCache.ships.first;
  const tradeSymbol = TradeSymbol.DIAMONDS;

  // List all markets nearby which buy diamonds.
  final trips = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    ship,
    tradeSymbol,
  );
  for (final trip in trips) {
    logger.info('Market: ${trip.route.endSymbol}, price: ${trip.price}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
