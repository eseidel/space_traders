import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
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
  DescribingVisitor(this.systems, this.db);

  final SystemsCache systems;
  final Database db;

  final _indent = ' ';

  @override
  Future<void> visitExtract(ExtractLink link, {required int depth}) async {
    final spaces = _indent * depth;
    final from = link.waypointSymbol.waypointName;
    logger.info('${spaces}Extract ${link.tradeSymbol} from $from');
  }

  @override
  Future<void> visitShuttle(ShuttleLink link, {required int depth}) async {
    final spaces = _indent * depth;
    final source = link.source.waypointSymbol;
    final destination = link.destination;
    final tradeSymbol = link.tradeSymbol;

    final distance = _distanceBetween(systems, source, destination);
    final sourcePrice = await db.marketPriceAt(source, tradeSymbol);
    final destinationPrice = await db.marketPriceAt(destination, tradeSymbol);

    logger.info(
      '${spaces}Shuttle $tradeSymbol from '
      '${_describeMarket(source, sourcePrice)} '
      'to ${_describeMarket(destination, destinationPrice)} '
      'distance = $distance',
    );
  }

  @override
  Future<void> visitManufacture(Manufacture link, {required int depth}) async {
    final spaces = _indent * depth;
    final inputSymbols = link.inputs.keys.map((s) => s.toString()).join(', ');
    logger.info(
      '${spaces}Manufacture ${link.tradeSymbol} '
      'at ${link.waypointSymbol} from $inputSymbols',
    );
  }
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final exports = TradeExportCache.load(fs);
  final systems = SystemsCache.load(fs)!;
  final marketListings = await MarketListingSnapshot.load(db);
  final agent = await myAgent(db);

  final jumpgate =
      systems.jumpGateWaypointForSystem(agent.headquarters.system)!;
  final waypointSymbol = jumpgate.symbol;
  final construction =
      (await db.getConstruction(waypointSymbol, defaultMaxAge))!.construction;

  final neededExports = construction!.materials
      .where((m) => m.required_ > m.fulfilled)
      .map((m) => m.tradeSymbol);
  for (final tradeSymbol in neededExports) {
    logger.info('Sourcing $tradeSymbol for $waypointSymbol');
    final action = SupplyChainBuilder(
      systems: systems,
      exports: exports,
      marketListings: marketListings,
    ).buildChainTo(tradeSymbol, waypointSymbol);
    if (action == null) {
      logger.warn('No supply chain to bring $tradeSymbol to $waypointSymbol');
      return;
    }
    await action.accept(DescribingVisitor(systems, db));
  }
}

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}
