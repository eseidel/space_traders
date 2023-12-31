import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  final marketListings = MarketListingCache.load(fs);
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);

  final connectedSystemSymbols =
      systemConnectivity.directlyConnectedSystemSymbols(startSystemSymbol);
  if (connectedSystemSymbols.isEmpty) {
    logger.info('No systems connected to $startSystemSymbol.');
    return;
  }
  for (final connectedSystemSymbol in connectedSystemSymbols) {
    final marketCount =
        marketListings.listingsInSystem(connectedSystemSymbol).length;
    logger.info(
      '${connectedSystemSymbol.system.padRight(9)} $marketCount markets',
    );
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
