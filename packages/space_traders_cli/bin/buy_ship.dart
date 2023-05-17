import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

String describeShipType(ShipType type, Shipyard shipyard) {
// This assumes there is only one ship available of each type in the yard.
  final ship = shipyard.ships.firstWhereOrNull(
    (s) => s.type == type,
  );
  final priceString = ship == null ? '' : ' - ${ship.purchasePrice}';
  return '$type$priceString';
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final agentResult = await api.agents.getMyAgent();

  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);
  final shipyardWaypoints =
      systemWaypoints.where((w) => w.hasShipyard).toList();

  final myShips = await allMyShips(api).toList();
  logger.info('Current ships:');
  printShips(myShips, systemWaypoints);
  logger.info('');

  final waypoint = logger.chooseOne(
    'From where?',
    choices: shipyardWaypoints,
    display: waypointDescription,
  );

  logger.info('Ships types available at ${waypoint.symbol}:');

  final shipyardResponse =
      await api.systems.getShipyard(waypoint.systemSymbol, waypoint.symbol);
  final shipyard = shipyardResponse!.data;

  final shipType = logger.chooseOne(
    'Which type?',
    choices: shipyard.shipTypes.map((t) => t.type!).toList(),
    display: (s) => describeShipType(s, shipyard),
  );

  logger.info('Purchasing $shipType.');
  final purchaseResponse = await purchaseShip(api, shipType, shipyard.symbol);
  logger.info('Purchased ${purchaseResponse.ship.symbol} for '
      '${creditsString(purchaseResponse.transaction.price)}.');
}
