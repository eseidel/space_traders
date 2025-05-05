import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/plan/ships.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final startSymbol = await startWaypointFromArg(
    db,
    argResults.rest.firstOrNull,
  );
  final shipyardShips = await ShipyardShipCache(db).snapshot();
  final systems = await SystemsSnapshot.load(db);
  final chartingSnapshot = await ChartingSnapshot.load(db);
  final systemConnectivity = await loadSystemConnectivity(db);

  final ships = await ShipSnapshot.load(db);
  final centralCommand = CentralCommand();

  final origin = systems.waypoint(startSymbol);
  final ship = shipyardShips.shipForTest(ShipType.PROBE, origin: origin)!;
  final maxJumps = config.charterMaxJumps;
  final behaviors = await BehaviorSnapshot.load(db);

  final destinationSymbol = await expectTime(
    RequestCounts(),
    db.queryCounts,
    'central planning',
    const Duration(seconds: 1),
    () async {
      centralCommand.nextWaypointToChart(
        ships,
        behaviors,
        systems,
        chartingSnapshot,
        systemConnectivity,
        ship,
        maxJumps: maxJumps,
      );
    },
  );
  if (destinationSymbol == null) {
    logger.info('No uncharted waypoints found within $maxJumps jumps.');
  } else {
    logger.info('Next uncharted waypoint: $destinationSymbol');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
