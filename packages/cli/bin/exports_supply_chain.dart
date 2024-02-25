import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/supply_chain.dart';

void source(
  MarketListingSnapshot marketListings,
  SystemsCache systemsCache,
  TradeExportCache exportCache,
  MarketPriceSnapshot marketPrices,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  logger.info('Sourcing $tradeSymbol for $waypointSymbol');
  final action = SupplyChainBuilder(
    marketListings,
    systemsCache,
    exportCache,
  ).buildChainTo(tradeSymbol, waypointSymbol);
  if (action == null) {
    logger.warn('No source for $tradeSymbol for $waypointSymbol');
    return;
  }
  final ctx = DescribeContext(systemsCache, marketPrices);
  action.describe(ctx);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final exportCache = TradeExportCache.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = await MarketListingSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.load(db);
  final agent = await myAgent(db);
  final constructionCache = ConstructionCache(db);

  final jumpgate =
      systemsCache.jumpGateWaypointForSystem(agent.headquarters.system)!;
  final waypointSymbol = jumpgate.symbol;
  final construction = await constructionCache.getConstruction(waypointSymbol);

  final neededExports = construction!.materials
      .where((m) => m.required_ > m.fulfilled)
      .map((m) => m.tradeSymbol);
  for (final tradeSymbol in neededExports) {
    source(
      marketListings,
      systemsCache,
      exportCache,
      marketPrices,
      tradeSymbol,
      waypointSymbol,
    );
  }
}

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}
