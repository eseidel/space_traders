import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';

String describeShipType(
  ShipType type,
  Shipyard shipyard,
  MarketPrices marketPrices,
) {
// This assumes there is only one ship available of each type in the yard.
  final ship = shipyard.ships.firstWhereOrNull(
    (s) => s.type == type,
  );
  final actualPriceString = ship == null ? '' : ' - ${ship.purchasePrice}';
  final medianPrice = marketPrices.medianPurchasePrice(type.value);
  final medianPriceString = medianPrice == null
      ? ''
      : ' - median price: ${creditsString(medianPrice)}';
  return '$type$actualPriceString$medianPriceString';
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final waypointFetcher =
      WaypointFetcher(api, caches.waypoints, caches.systems);
  final hq = caches.agent.headquarters(caches.systems);
  final shipyardWaypoints =
      await waypointFetcher.shipyardWaypointsForSystem(hq.systemSymbol);

  final ships = caches.ships.ships;
  logger.info('Current ships:');
  printShips(ships, caches.systems);
  logger.info('');

  final waypoint = logger.chooseOne(
    'From where?',
    choices: shipyardWaypoints,
    display: waypointDescription,
  );

  final beforeCredits = creditsString(caches.agent.agent.credits);
  logger
    ..info('$beforeCredits credits available.')
    ..info('Ships types available at ${waypoint.symbol}:');

  final shipyardResponse =
      await api.systems.getShipyard(waypoint.systemSymbol, waypoint.symbol);
  final shipyard = shipyardResponse!.data;

  final shipType = logger.chooseOne(
    'Which type?',
    choices: shipyard.shipTypes.map((t) => t.type!).toList(),
    display: (s) => describeShipType(s, shipyard, caches.marketPrices),
  );

  logger.info('Purchasing $shipType.');
  final purchaseResponse = await purchaseShip(
    api,
    caches.ships,
    caches.agent,
    shipyard.symbol,
    shipType,
  );
  logger.info('Purchased ${purchaseResponse.ship.symbol} for '
      '${creditsString(purchaseResponse.transaction.price)}.');
  final afterCredits = creditsString(purchaseResponse.agent.credits);
  logger.info('$afterCredits credits remaining.');
}
