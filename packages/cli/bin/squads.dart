import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/ship_snapshot.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';

String describeJob(ExtractionJob job) {
  final action = job.extractionType.name;
  final sourceName = job.source.sectorLocalName;
  return '$action @ $sourceName';
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final systems = await SystemsCache.loadOrFetch(fs);
  final charting = ChartingCache(db);
  final ships = await ShipSnapshot.load(db);
  final shipyardShipCache = ShipyardShipCache.load(fs);

  final squads = await assignShipsToSquads(
    db,
    systems,
    charting,
    ships,
    systemSymbol: ships.ships.first.systemSymbol,
  );
  logger.info('${squads.length} squads');

  for (var i = 0; i < squads.length; i++) {
    final squad = squads[i];
    logger.info('Squad $i: ${describeJob(squad.job)}');
    for (final ship in squad.ships) {
      final type = guessShipType(shipyardShipCache, ship)!;
      final typeName = type.value.substring('SHIP_'.length);
      final cargoStatus = ship.cargo.capacity == 0
          ? ''
          : '${ship.cargo.units}/${ship.cargo.capacity}';
      logger.info('  ${ship.shipSymbol.hexNumber.padLeft(2)} $typeName '
          '${ship.nav.waypointSymbolObject} $cargoStatus');
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
