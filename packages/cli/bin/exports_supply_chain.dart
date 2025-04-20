import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/plan/supply_chain.dart';

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

String _describeGood(TradeSymbol tradeSymbol, MarketPrice? price) {
  if (price == null) {
    return '$tradeSymbol null';
  }
  return '$tradeSymbol (${price.supply}, '
      '${price.activity}, ${price.tradeVolume})';
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
    logger.info(
      '${spaces}Shuttle $tradeSymbol from '
      '${source.waypointName} to ${destination.waypointName} '
      'distance = $distance',
    );
  }

  @override
  Future<void> visitManufacture(
    ManufactureLink link, {
    required int depth,
  }) async {
    final spaces = _indent * depth;
    final inputStrings = <String>[];
    final waypointSymbol = link.waypointSymbol;
    for (final inputSymbol in link.inputs.keys) {
      final price = await db.marketPriceAt(waypointSymbol, inputSymbol);
      inputStrings.add(_describeGood(inputSymbol, price));
    }
    final inputSymbols = inputStrings.join(', ');
    final name = link.waypointSymbol.waypointName;
    final sourcePrice = await db.marketPriceAt(
      link.waypointSymbol,
      link.tradeSymbol,
    );
    logger.info(
      '${spaces}Manufacture ${_describeGood(link.tradeSymbol, sourcePrice)} '
      'at $name from $inputSymbols',
    );
  }
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final exports = TradeExportCache.load(fs);
  final systems = SystemsCache.load(fs);
  final marketListings = await MarketListingSnapshot.load(db);
  final charting = await ChartingSnapshot.load(db);
  final agent = await db.getMyAgent();

  final jumpgate =
      systems.jumpGateWaypointForSystem(agent!.headquarters.system)!;
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
      charting: charting,
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
