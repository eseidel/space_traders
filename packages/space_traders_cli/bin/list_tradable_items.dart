import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';

void main() async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);
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
