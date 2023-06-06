import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

String describeShipType(ShipType type, Shipyard shipyard, PriceData priceData) {
// This assumes there is only one ship available of each type in the yard.
  final ship = shipyard.ships.firstWhereOrNull(
    (s) => s.type == type,
  );
  final actualPriceString = ship == null ? '' : ' - ${ship.purchasePrice}';
  final medianPrice = priceData.medianPurchasePrice(type.value);
  final medianPriceString = medianPrice == null
      ? ''
      : ' - median price: ${creditsString(medianPrice)}';
  return '$type$actualPriceString$medianPriceString';
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  final priceData = await PriceData.load(fs);

  final agent = await getMyAgent(api);
  final hq = await waypointCache.getAgentHeadquarters();
  final shipyardWaypoints =
      await waypointCache.shipyardWaypointsForSystem(hq.systemSymbol);

  final myShips = await allMyShips(api).toList();
  final shipWaypoints = await waypointsForShips(waypointCache, myShips);
  logger.info('Current ships:');
  printShips(myShips, shipWaypoints);
  logger.info('');

  final waypoint = logger.chooseOne(
    'From where?',
    choices: shipyardWaypoints,
    display: waypointDescription,
  );

  final beforeCredits = creditsString(agent.credits);
  logger
    ..info('$beforeCredits credits available.')
    ..info('Ships types available at ${waypoint.symbol}:');

  final shipyardResponse =
      await api.systems.getShipyard(waypoint.systemSymbol, waypoint.symbol);
  final shipyard = shipyardResponse!.data;

  final shipType = logger.chooseOne(
    'Which type?',
    choices: shipyard.shipTypes.map((t) => t.type!).toList(),
    display: (s) => describeShipType(s, shipyard, priceData),
  );

  logger.info('Purchasing $shipType.');
  final purchaseResponse = await purchaseShip(api, shipType, shipyard.symbol);
  logger.info('Purchased ${purchaseResponse.ship.symbol} for '
      '${creditsString(purchaseResponse.transaction.price)}.');
  final afterCredits = creditsString(purchaseResponse.agent.credits);
  logger.info('$afterCredits credits remaining.');
}
