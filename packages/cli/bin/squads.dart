import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/ships.dart';

String describeJob(ExtractionJob job) {
  final action = job.extractionType.name;
  final sourceName = job.source.sectorLocalName;
  return '$action @ $sourceName';
}

ShipType? guessType(ShipyardShipCache shipyardShipCache, Ship ship) {
  final frame = ship.frame;
  final type = shipyardShipCache.shipTypeFromFrame(frame.symbol);
  if (type != null) {
    return type;
  }
  if (frame.symbol == ShipFrameSymbolEnum.DRONE) {
    if (ship.hasMiningLaser) {
      return ShipType.MINING_DRONE;
    }
    if (ship.hasSurveyor) {
      return ShipType.SURVEYOR;
    }
  }
  return null;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final systems = await SystemsCache.loadOrFetch(fs);
  final waypointTraits = WaypointTraitCache.load(fs);
  // TODO(eseidel): This should not need a ChartingCache or ConstructionCache.
  final charting = ChartingCache(db);
  final construction = ConstructionCache(db);
  final waypointCache =
      WaypointCache.cachedOnly(systems, charting, construction, waypointTraits);
  final shipCache = ShipCache.load(fs)!;
  final tradeGoods = TradeGoodCache.load(fs);
  final marketListings = MarketListingCache.load(fs, tradeGoods);
  final shipyardShipCache = ShipyardShipCache.load(fs);

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
    logger.info('Squad $i: ${describeJob(squad.job)}');
    for (final ship in squad.ships) {
      final type = guessType(shipyardShipCache, ship)!;
      final typeName = type.value.substring('SHIP_'.length);
      final cargoStatus = ship.cargo.capacity == 0
          ? ''
          : '${ship.cargo.units}/${ship.cargo.capacity}';
      logger.info('  ${ship.shipSymbol.hexNumber.padLeft(2)} $typeName '
          '${ship.nav.waypointSymbolObject} $cargoStatus');
    }
  }
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
