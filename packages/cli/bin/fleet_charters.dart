import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

// Could share with fleet.dart
void logShip(
  SystemsCache systemsCache,
  BehaviorCache behaviorCache,
  MarketPrices marketPrices,
  Ship ship,
) {
  const indent = '   ';
  final behavior = behaviorCache.getBehavior(ship.shipSymbol);
  final waypoint = systemsCache.waypoint(ship.waypointSymbol);
  logger.info(ship.shipSymbol.hexNumber);

  final routePlan = behavior?.routePlan;
  if (routePlan != null) {
    final timeLeft = ship.timeToArrival(routePlan);
    final destination = routePlan.endSymbol.sectorLocalName;
    final destinationType = systemsCache.waypoint(routePlan.endSymbol).type;
    final arrival = approximateDuration(timeLeft);
    logger.info('${indent}enroute to $destination $destinationType '
        'in $arrival');
  } else {
    logger.info('$indent${describeShipNav(ship.nav)} ${waypoint.type}');
  }
  final deal = behavior?.deal;
  if (deal != null) {
    logger.info('$indent${describeCostedDeal(deal)}');
    final since = DateTime.timestamp().difference(deal.startTime);
    logger.info('${indent}duration: ${approximateDuration(since)}');
  }
}

String plural(int count, String singular, [String plural = 's']) {
  return '$count ${count == 1 ? singular : singular + plural}';
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final behaviorCache = await BehaviorCache.load(db);
  final charterStates =
      behaviorCache.states.where((s) => s.behavior == Behavior.charter);
  final systemsCache = SystemsCache.load(fs)!;
  final shipCache = await ShipSnapshot.load(db);

  logger.info('${plural(charterStates.length, 'charter')}:');
  for (final state in charterStates) {
    final shipSymbol = state.shipSymbol;
    final ship = shipCache[shipSymbol];
    final navString = describeShipNav(ship.nav);
    logger.info('${ship.emojiName} $navString');

    final routePlan = state.routePlan;
    if (routePlan != null) {
      final timeLeft = ship.timeToArrival(routePlan);
      final destination = routePlan.endSymbol.sectorLocalName;
      final destinationType = systemsCache.waypoint(routePlan.endSymbol).type;
      final arrival = approximateDuration(timeLeft);
      logger.info('  enroute to $destination $destinationType in $arrival');
    }
  }
}
