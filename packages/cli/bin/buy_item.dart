import 'package:cli/cache/caches.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';

String displayGood(MarketTradeGood good) {
  return '${good.symbol} @ ${creditsString(good.purchasePrice)}';
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.systems, myShips);

  if (ship.availableSpace < 1) {
    logger.err('No cargo space available on ${ship.symbol}!}');
    return;
  }

  await dockIfNeeded(api, ship);
  final waypointFetcher =
      WaypointFetcher(api, caches.waypoints, caches.systems);
  final marketFetcher = MarketFetcher(api, waypointFetcher, caches.systems);
  final market = await marketFetcher.marketForSymbol(ship.nav.waypointSymbol);

  // List all the goods this market sells with their prices.
  final good = logger.chooseOne(
    'Which item type?',
    choices: market!.tradeGoods,
    display: displayGood,
  );

  final purchasePrice = good.purchasePrice;
  final maxBuy = caches.agent.agent.credits ~/ purchasePrice;

  if (maxBuy < 1) {
    logger.err("You can't afford any of those!");
    return;
  }

  final quantity = int.parse(logger.prompt('How many?'));

  await purchaseCargoAndLog(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    ship,
    TradeSymbol.fromJson(good.symbol)!,
    quantity,
  );
}
