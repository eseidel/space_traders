import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/shipyard_prices.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/transactions.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

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
      final market = await marketCache.marketForSymbol(destination.symbol);
      await recordMarketDataAndLog(priceData, market!, ship);
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
  final ship = await chooseShip(api, waypointCache, myShips);

  final startingSystem =
      await waypointCache.systemBySymbol(ship.nav.systemSymbol);
  final jumpGate = await waypointCache.jumpGateForSystem(ship.nav.systemSymbol);
  final jumpGateWaypoint =
      await waypointCache.jumpGateWaypointForSystem(ship.nav.systemSymbol);

  final systemChoices = [
    connectedSystemFromSystem(startingSystem, 0),
    ...jumpGate!.connectedSystems,
  ];

  final destSystem = logger.chooseOne(
    'To which system?',
    choices: systemChoices,
    display: (system) => '${system.symbol} - ${system.distance}',
  );

  final destSystemWaypoints =
      await waypointCache.waypointsInSystem(destSystem.symbol);

  final destWaypoint = logger.chooseOne(
    'To where?',
    choices: destSystemWaypoints,
    display: waypointDescription,
  );

  final shouldDock = logger.confirm('Wait to dock?', defaultValue: true);

  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  if (currentWaypoint.hasMarketplace && ship.shouldRefuel) {
    final market = await marketCache.marketForSymbol(currentWaypoint.symbol);
    await refuelIfNeededAndLog(
      api,
      priceData,
      transactionLog,
      agent,
      market!,
      ship,
    );
  }

  if (destWaypoint.systemSymbol == startingSystem.symbol) {
    await _navigateToLocalWaypointAndDock(
      api,
      agent,
      priceData,
      shipyardPrices,
      marketCache,
      transactionLog,
      ship,
      destWaypoint,
      shouldDock,
    );
    return;
  }

  // This only handles a single jump at this point.

  // If we aren't at the jump gate, navigate to it.
  if (ship.nav.waypointSymbol != jumpGateWaypoint!.symbol) {
    final arrival = await navigateToLocalWaypointAndLog(
      api,
      ship,
      jumpGateWaypoint,
    );
    await Future<void>.delayed(durationUntil(arrival));
  }
  final jumpRequest = JumpShipRequest(systemSymbol: destSystem.symbol);
  await api.fleet.jumpShip(ship.symbol, jumpShipRequest: jumpRequest);
  // We don't need to wait after the jump cooldown.
  await _navigateToLocalWaypointAndDock(
    api,
    agent,
    priceData,
    shipyardPrices,
    marketCache,
    transactionLog,
    ship,
    destWaypoint,
    shouldDock,
  );
}
