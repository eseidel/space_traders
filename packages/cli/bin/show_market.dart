import 'package:cli/cache/caches.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.systems, myShips);
  final waypointFetcher =
      WaypointFetcher(api, caches.waypoints, caches.systems);
  final marketFetcher = MarketFetcher(api, waypointFetcher, caches.systems);

  final marketplaceWaypoints =
      await waypointFetcher.marketWaypointsForSystem(ship.nav.systemSymbol);

  final waypoint = logger.chooseOne(
    'Which marketplace?',
    choices: marketplaceWaypoints,
    display: waypointDescription,
  );

  final market = await marketFetcher.marketForSymbol(waypoint.symbol);
  prettyPrintJson(market!.toJson());
}
