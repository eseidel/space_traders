import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void main() async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);
  final marketCache = MarketCache(waypointCache);

  final ships = await allMyShips(api).toList();
  final ship = ships.first;

  final connectedSystems =
      waypointCache.connectedSystems(ship.nav.systemSymbol);
  final markets = await connectedSystems
      .asyncExpand((s) => marketCache.marketsInSystem(s.symbol))
      .toList();

  // Collect all the trade symbols and their market counts.
  final tradeSymbolCounts = <String, int>{};
  for (final market in markets) {
    for (final tradeSymbol in market.allTradeSymbols) {
      tradeSymbolCounts[tradeSymbol.value] =
          (tradeSymbolCounts[tradeSymbol.value] ?? 0) + 1;
    }
  }
  // print them out in order of most markets to least.
  final tradeSymbols = tradeSymbolCounts.keys.toList()
    ..sort((a, b) => tradeSymbolCounts[b]!.compareTo(tradeSymbolCounts[a]!));
  for (final tradeSymbol in tradeSymbols) {
    logger.info(
      '$tradeSymbol: ${tradeSymbolCounts[tradeSymbol]} markets',
    );
  }
}
