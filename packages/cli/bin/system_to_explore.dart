import 'package:cli/behavior/explorer.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final ship = shipCache.ships.first;
  final systemsCache = SystemsCache.loadCached(fs)!;
  final chartingCache = ChartingCache.load(fs);
  final systemConnectivity = SystemConnectivity.fromSystemsCache(systemsCache);
  final marketPrices = MarketPrices.load(fs);
  final shipyardPrices = ShipyardPrices.load(fs);

  final destinationSymbol = await findNewWaypointSymbolToExplore(
    systemsCache,
    systemConnectivity,
    chartingCache,
    marketPrices,
    shipyardPrices,
    ship,
    startSystemSymbol: ship.systemSymbol,
  );
  if (destinationSymbol == null) {
    logger.info('No new waypoints to explore.');
    return;
  }
  logger.info('Exploring $destinationSymbol.');
}

void main(List<String> args) async {
  await runOffline(args, command);
}