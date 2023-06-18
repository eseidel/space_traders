import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
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

Future<void> _navigateToLocalWaypointAndDock(
  Api api,
  AgentCache agentCache,
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
          agentCache,
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
  final agentCache = await AgentCache.load(api);

  final myShips = await allMyShips(api).toList();
  final ship = await chooseShip(api, waypointCache, myShips);

  final startSystemSymbol = ship.nav.systemSymbol;
  final startingSystem = systemsCache.systemBySymbol(startSystemSymbol);
  final jumpGate = await waypointCache.jumpGateForSystem(startSystemSymbol);
  final jumpGateWaypoint =
      systemsCache.jumpGateWaypointForSystem(startSystemSymbol);

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
      agentCache,
      market!,
      ship,
    );
  }

  if (destWaypoint.systemSymbol == startingSystem.symbol) {
    await _navigateToLocalWaypointAndDock(
      api,
      agentCache,
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
    agentCache,
    priceData,
    shipyardPrices,
    marketCache,
    transactionLog,
    ship,
    destWaypoint,
    shouldDock,
  );
}
