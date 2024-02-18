import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  final marketListings = await MarketListingSnapshot.load(db);
  final systemConnectivity = await loadSystemConnectivity(db);

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
