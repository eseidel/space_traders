import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/cli.dart';

String describeJob(ExtractionJob job) {
  final action = job.extractionType.name;
  final sourceName = job.source.sectorLocalName;
  return '$action @ $sourceName';
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final systems = await SystemsCache.loadOrFetch(fs);
  final waypointTraits = WaypointTraitCache.load(fs);
  final charting = ChartingCache.load(fs, waypointTraits);
  final construction = ConstructionCache.load(fs);
  final waypointCache =
      WaypointCache.cachedOnly(systems, charting, construction);
  final shipCache = ShipCache.load(fs)!;
  final tradeGoods = TradeGoodCache.load(fs);
  final marketListings = MarketListingCache.load(fs, tradeGoods);

  final squads = await assignShipsToSquads(
    systems,
    waypointCache,
    marketListings,
    shipCache,
    systemSymbol: shipCache.ships.first.systemSymbol,
  );
  logger.info('${squads.length} squads');
  for (var i = 0; i < squads.length; i++) {
    final squad = squads[i];
    logger
      ..info('Squad $i:')
      ..info('  job: ${describeJob(squad.job)}');
    for (final ship in squad.ships) {
      logger.info(
        '  ${ship.symbol} ${ship.frame.symbol} ${ship.mountedMountSymbols}',
      );
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
