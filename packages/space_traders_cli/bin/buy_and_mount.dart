import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/shipyard_prices.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/actions.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/trading.dart';

Future<void> _navigateToLocalWaypointAndDock(
  Api api,
  Agent agent,
  PriceData priceData,
  ShipyardPrices shipyardPrices,
  MarketCache marketCache,
  TransactionLog transactionLog,
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
    if (destination.hasMarketplace) {
      final market = await recordMarketDataIfNeededAndLog(
        priceData,
        marketCache,
        ship,
        destination.symbol,
      );
      if (ship.shouldRefuel) {
        await refuelIfNeededAndLog(
          api,
          priceData,
          transactionLog,
          agent,
          market,
          ship,
        );
      }
    }
    if (destination.hasShipyard) {
      final shipyard = await getShipyard(api, destination);
      await recordShipyardDataAndLog(shipyardPrices, shipyard, ship);
    }
    logger.info('Docked.');
  }
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);
  final marketCache = MarketCache(waypointCache);
  final priceData = await PriceData.load(fs);
  final shipyardPrices = await ShipyardPrices.load(fs);
  final transactionLog = await TransactionLog.load(fs);
  final agent = await getMyAgent(api);

  final myShips = await allMyShips(api).toList();
  // pick a ship.
  final ship = await chooseShip(api, waypointCache, myShips);
  // pick a mount.
  const tradeSymbol = TradeSymbol.MOUNT_SURVEYOR_II;

  // it finds a nearby market with that mount.
  final start = await waypointCache.waypoint(ship.nav.waypointSymbol);
  final mountMarket = await nearbyMarketWhichTrades(
    systemsCache,
    waypointCache,
    marketCache,
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
    agent,
    priceData,
    shipyardPrices,
    marketCache,
    transactionLog,
    ship,
    mountMarket,
    true,
  );
  // Buys the mount.
  await purchaseCargoAndLog(
    api,
    priceData,
    transactionLog,
    ship,
    tradeSymbol,
    1,
  );
  // mounts the mount.
  await installMountAndLog(api, ship, tradeSymbol.value);
}
