import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // List all known asteroids that have a market or shipyard.
  final marketListings = await MarketListingSnapshot.load(db);
  final shipyardListings = await ShipyardListingSnapshot.load(db);

  for (final marketListing in marketListings.listings) {
    final waypointSymbol = marketListing.waypointSymbol;
    final waypoint = await db.systems.waypoint(waypointSymbol);
    if (!waypoint.isAsteroid) {
      continue;
    }
    final shipyardListing = shipyardListings[waypointSymbol];
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
