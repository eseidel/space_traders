import 'package:cli/behavior/explorer.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

Future<void> _navigateToLocalWaypointAndDock(
  Api api,
  Caches caches,
  Ship ship,
  Waypoint destination,
  bool shouldDock,
) async {
  final navigateResult =
      await navigateToLocalWaypoint(api, ship, destination.symbol);
  final eta = navigateResult.nav.route.arrival;
  final flightTime = eta.difference(DateTime.now());
  logger.info('Expected in $flightTime.');
  if (shouldDock) {
    logger.info('Waiting to dock...');
    await Future<void>.delayed(flightTime);
    await dockIfNeeded(api, ship);
    await visitLocalMarket(api, caches, destination, ship);
    await visitLocalShipyard(api, caches.shipyardPrices, destination, ship);
    logger.info('Docked.');
  }
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = await allMyShips(api).toList();
  // pick a ship.
  final ship = await chooseShip(api, caches.systems, myShips);
  // pick a mount.
  const tradeSymbol = TradeSymbol.MOUNT_SURVEYOR_II;

  // it finds a nearby market with that mount.
  final start = await caches.waypoints.waypoint(ship.nav.waypointSymbol);
  final mountMarket = await nearbyMarketWhichTrades(
    caches.systems,
    caches.waypoints,
    caches.markets,
    start,
    tradeSymbol.value,
    maxJumps: 10,
  );
  if (mountMarket == null) {
    logger.info('No nearby market with $tradeSymbol.');
    return;
  }
  logger.info('Found $tradeSymbol at ${mountMarket.symbol}.');
  // navigates there.
  await _navigateToLocalWaypointAndDock(
    api,
    caches,
    ship,
    mountMarket,
    true,
  );
  // Buys the mount.
  await purchaseCargoAndLog(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    ship,
    tradeSymbol,
    1,
  );
  // mounts the mount.
  await installMountAndLog(api, ship, tradeSymbol.value);
}
