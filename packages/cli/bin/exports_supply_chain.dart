import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/supply_chain.dart';

// Returns the distance between two waypoints, or null if they are in different
// systems.
int? _distanceBetween(
  SystemsCache systemsCache,
  WaypointSymbol a,
  WaypointSymbol b,
) {
  final aWaypoint = systemsCache.waypoint(a);
  final bWaypoint = systemsCache.waypoint(b);
  if (aWaypoint.system != bWaypoint.system) {
    return null;
  }
  return aWaypoint.distanceTo(bWaypoint).toInt();
}

String _describeMarket(WaypointSymbol waypointSymbol, MarketPrice? price) {
  final name = waypointSymbol.waypointName;
  if (price == null) {
    return '$name (no market)';
  }
  return '$name (${price.supply}, ${price.activity})';
}

/// Walk the supply chain and print it.
class DescribingVisitor extends SupplyLinkVisitor {
  /// Create a new describing visitor.
  DescribingVisitor(this.systems, this.marketPrices);

  /// The systems cache.
  final SystemsCache systems;

  /// The market prices.
  final MarketPriceSnapshot marketPrices;

  final _indent = ' ';

  @override
  void visitExtract(ExtractLink link, {required int depth}) {
    final spaces = _indent * depth;
    final from = link.waypointSymbol.waypointName;
    logger.info('${spaces}Extract ${link.tradeSymbol} from $from');
  }

  @override
  void visitShuttle(ShuttleLink link, {required int depth}) {
    final spaces = _indent * depth;
    final source = link.source.waypointSymbol;
    final destination = link.destination;
    final tradeSymbol = link.tradeSymbol;

    final distance = _distanceBetween(systems, source, destination);
    final sourcePrice = marketPrices.priceAt(source, tradeSymbol);
    final destinationPrice = marketPrices.priceAt(destination, tradeSymbol);

    logger.info(
      '${spaces}Shuttle $tradeSymbol from '
      '${_describeMarket(source, sourcePrice)} '
      'to ${_describeMarket(destination, destinationPrice)} '
      'distance = $distance',
    );
  }

  @override
  void visitManufacture(Manufacture link, {required int depth}) {
    final spaces = _indent * depth;
    final inputSymbols = link.inputs.keys.map((s) => s.toString()).join(', ');
    logger.info(
      '${spaces}Manufacture ${link.tradeSymbol} '
      'at ${link.waypointSymbol} from $inputSymbols',
    );
  }
}

void source(
  MarketListingSnapshot marketListings,
  SystemsCache systems,
  TradeExportCache exports,
  MarketPriceSnapshot marketPrices,
  TradeSymbol tradeSymbol,
  WaypointSymbol waypointSymbol,
) {
  logger.info('Sourcing $tradeSymbol for $waypointSymbol');
  final action = SupplyChainBuilder(
    systems: systems,
    exports: exports,
    marketListings: marketListings,
  ).buildChainTo(tradeSymbol, waypointSymbol);
  if (action == null) {
    logger.warn('No source for $tradeSymbol for $waypointSymbol');
    return;
  }
  action.accept(DescribingVisitor(systems, marketPrices));
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
