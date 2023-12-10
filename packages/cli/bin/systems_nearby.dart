import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  final staticCaches = StaticCaches.load(fs);

  final marketListings = MarketListingCache.load(fs, staticCaches.tradeGoods);
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionCache = ConstructionCache.load(fs);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionCache);

  final connectedSystemSymbols =
      systemConnectivity.directlyConnectedSystemSymbols(startSystemSymbol);
  for (final connectedSystemSymbol in connectedSystemSymbols) {
    final marketCount =
        marketListings.listingsInSystem(connectedSystemSymbol).length;
    logger.info(
      '${connectedSystemSymbol.system.padRight(9)} $marketCount markets',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
