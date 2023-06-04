import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void main() async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);
  final marketCache = MarketCache(waypointCache);

  final priceData = await PriceData.load(fs);

  final market = await marketCache.marketForSymbol('X1-TY89-82996C');
  final price = estimateSellPrice(
    priceData,
    TradeSymbol.fromJson('MEDICINE')!,
    market!,
  );
  final string = price == null ? 'null' : creditsString(price);
  logger.info(string);
}
