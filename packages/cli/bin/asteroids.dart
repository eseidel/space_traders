import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // List all known asteroids that have a market or shipyard.
  final tradeGoods = TradeGoodCache.load(fs);
  final marketListingsCache = MarketListingCache.load(fs, tradeGoods);
  final shipyardListingCache = ShipyardListingCache.load(fs);
  final systemsCache = SystemsCache.load(fs)!;

  for (final marketListing in marketListingsCache.listings) {
    final waypointSymbol = marketListing.waypointSymbol;
    final waypoint = systemsCache.waypoint(waypointSymbol);
    if (!waypoint.isAsteroid) {
      continue;
    }
    final shipyardListing = shipyardListingCache[waypointSymbol];
    if (shipyardListing != null) {
      logger.info('Asteroid $waypointSymbol has a market and shipyard.');
    } else {
      logger.info('Asteroid $waypointSymbol has a market.');
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
