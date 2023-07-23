import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final ships = caches.ships.ships;
  final ship = ships.first;

  final connectedSystems = caches.waypoints.connectedSystems(ship.systemSymbol);
  final markets = await connectedSystems
      .asyncExpand((s) => caches.markets.marketsInSystem(s.systemSymbol))
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
