import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

void main(List<String> args) async {
  await runOffline(args, command);
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

Duration timeToDestination(
  SystemsCache systemsCache,
  Ship ship,
  String destinationSymbol,
) {
  var time = Duration.zero;
  if (ship.isInTransit) {
    time += ship.nav.route.arrival.difference(DateTime.timestamp());
  }
  // We could find this waypoint in the Deal route and take the reamining
  // actions and compute from those?
  final start = systemsCache.waypointFromSymbol(ship.nav.waypointSymbol);
  final end = systemsCache.waypointFromSymbol(destinationSymbol);
  final route = planRoute(
    systemsCache,
    start: start,
    end: end,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  if (route == null) {
    shipWarn(ship, 'No route to $destinationSymbol!?');
    return time;
  }
  return time + Duration(seconds: route.duration);
}

Future<void> command(FileSystem fs, List<String> args) async {
  final behaviorCache = await BehaviorCache.load(fs);
  final shipCache = ShipCache.loadCached(fs)!;
  final systemsCache = SystemsCache.loadFromCache(fs)!;

  final centralCommand = CentralCommand(behaviorCache, shipCache);
  logger.info(describeFleet(shipCache));
  final ships = shipCache.ships;
  for (final ship in ships) {
    final behavior = centralCommand.getBehavior(ship.symbol);
    logger
      ..info('${ship.symbol}: ${behavior?.behavior}')
      ..info('  ${_shipStatusLine(ship, systemsCache)}');
    final destination = behavior?.destination;
    if (destination != null) {
      final timeToArrival = timeToDestination(systemsCache, ship, destination);
      logger.info('  destination: $destination, '
          'arrives in ${approximateDuration(timeToArrival)}');
    }
    final deal = behavior?.deal;
    if (deal != null) {
      logger.info('  ${describeCostedDeal(deal)}');
    }
  }
}
