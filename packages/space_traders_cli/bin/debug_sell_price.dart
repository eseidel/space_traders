import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/queries.dart';

void main() async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);
  final marketCache = MarketCache(waypointCache);

  final priceData = await PriceData.load(fs);
  final ships = await allMyShips(api).toList();
  final ship = ships.first;

  // final market = await marketCache.marketForSymbol('X1-DB96-67013B');
  // final price = estimatePurchasePrice(
  //   priceData,
  //   TradeSymbol.fromJson('BOTANICAL_SPECIMENS')!,
  //   market!,
  // );
  final deal = await findBestDealWithinOneJump(
    priceData,
    ship,
    waypointCache,
    marketCache,
  );
  logDeal(ship, deal!);
}
