import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final agentCache = AgentCache.load(fs)!;
  final hqSystemSymbol = agentCache.headquartersSystemSymbol;
  final staticCaches = StaticCaches.load(fs);

  final marketListings = MarketListingCache.load(fs, staticCaches.tradeGoods);
  final jumpGateCache = JumpGateCache.load(fs);

  final systemConnectivity =
      SystemConnectivity.fromJumpGateCache(jumpGateCache);

  final connectedSystemSymbols =
      systemConnectivity.directlyConnectedSystemSymbols(hqSystemSymbol);
  for (final systemSymbol in connectedSystemSymbols) {
    final marketCount = marketListings.listingsInSystem(systemSymbol).length;
    logger.info(
      '${systemSymbol.system.padRight(9)} $marketCount markets',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
