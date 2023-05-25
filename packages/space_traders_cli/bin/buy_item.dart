import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

String displayGood(MarketTradeGood good) {
  return '${good.symbol} @ ${creditsString(good.purchasePrice)}';
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final priceData = await PriceData.load(fs);
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final waypointCache = WaypointCache(api);
  final marketCache = MarketCache(waypointCache);
  final systemWaypoints = await waypointCache.waypointsInSystem(hq.system);

  final myShips = await allMyShips(api).toList();
  final ship = logger.chooseOne(
    'Which ship?',
    choices: myShips,
    display: (ship) => shipDescription(ship, systemWaypoints),
  );

  if (ship.availableSpace < 1) {
    logger.err('No cargo space available on ${ship.symbol}!}');
    return;
  }

  // Dock if needed?

  final market = await marketCache.marketForSymbol(ship.nav.waypointSymbol);

  // List all the goods this market sells with their prices.
  final good = logger.chooseOne(
    'Which item type?',
    choices: market!.tradeGoods,
    display: displayGood,
  );

  final purchasePrice = good.purchasePrice;
  final maxBuy = agent.credits ~/ purchasePrice;

  if (maxBuy < 1) {
    logger.err("You can't afford any of those!");
    return;
  }

  final quantity = int.parse(logger.prompt('How many?'));

  await purchaseCargoAndLog(api, priceData, ship, good.symbol, quantity);
}
