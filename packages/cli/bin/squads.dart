import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';

String describeJob(ExtractionJob job) {
  final action = job.extractionType.name;
  final sourceName = job.source.sectorLocalName;
  return '$action @ $sourceName';
}

Future<void> command(Database db, ArgResults argResults) async {
  final systems = await db.systems.snapshotAllSystems();
  final ships = await ShipSnapshot.load(db);
  final shipyardShips = await db.shipyardShips.snapshot();

  final squads = await assignShipsToSquads(
    db,
    systems,
    ships,
    systemSymbol: ships.ships.first.systemSymbol,
  );
  logger.info('${squads.length} squads');

  for (var i = 0; i < squads.length; i++) {
    final squad = squads[i];
    logger.info('Squad $i: ${describeJob(squad.job)}');
    for (final ship in squad.ships) {
      final type = shipyardShips.guessShipType(ship)!;
      final typeName = type.value.substring('SHIP_'.length);
      final cargoStatus =
          ship.cargo.capacity == 0
              ? ''
              : '${ship.cargo.units}/${ship.cargo.capacity}';
      logger.info(
        '  ${ship.symbol.hexNumber.padLeft(2)} $typeName '
        '${ship.nav.waypointSymbolObject} $cargoStatus',
      );
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
