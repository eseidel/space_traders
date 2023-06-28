import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/trading.dart';

void main(List<String> args) async {
  await run(args, command);
}

String _shipStatusLine(Ship ship, SystemsCache systemsCache) {
  final waypoint = systemsCache.waypointFromSymbol(ship.nav.waypointSymbol);
  var string =
      '${ship.navStatusString} ${waypoint.type} ${ship.registration.role} ${ship.cargo.units}/${ship.cargo.capacity}';
  if (ship.crew.morale != 100) {
    string += ' (morale: ${ship.crew.morale})';
  }
  if (ship.averageCondition != 100) {
    string += ' (condition: ${ship.averageCondition})';
  }
  return string;
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final centralCommand = CentralCommand(caches.behaviors, caches.ships);
  logger.info(describeFleet(caches.ships));
  final ships = caches.ships.ships;
  for (final ship in ships) {
    final behavior = centralCommand.getBehavior(ship.symbol);
    logger
      ..info('${ship.symbol}: ${behavior?.behavior}')
      ..info('  ${_shipStatusLine(ship, caches.systems)}');
    final destination = behavior?.destination;
    if (destination != null) {
      logger.info('  destination: $destination');
    }
    final deal = behavior?.deal;
    if (deal != null) {
      logger.info('  ${describeCostedDeal(deal)}');
    }
  }
}
