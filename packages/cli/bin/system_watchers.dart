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
  final marketListings = await MarketListingSnapshot.load(db);
  final systemsToWatch = marketListings.systemsWithAtLeastNMarkets(5);

  final behaviorCache = await BehaviorCache.load(db);
  final systemWatcherStates =
      behaviorCache.states.where((s) => s.behavior == Behavior.systemWatcher);
  final systemsCache = SystemsCache.load(fs)!;
  // final marketPrices = MarketPrices.load(fs);
  final shipCache = await ShipSnapshot.load(db);

  logger.info('${plural(systemWatcherStates.length, 'watcher')} assigned:');
  for (final state in systemWatcherStates) {
    final shipSymbol = state.shipSymbol;
    final assignedSystemName =
        state.systemWatcherJob?.systemSymbol.systemName.padRight(4);
    final ship = shipCache[shipSymbol];
    final navString = describeShipNav(ship.nav);
    logger
        .info('${ship.emojiName} assigned to $assignedSystemName, $navString');

    final routePlan = state.routePlan;
    if (routePlan != null) {
      final timeLeft = ship.timeToArrival(routePlan);
      final destination = routePlan.endSymbol.sectorLocalName;
      final destinationType = systemsCache.waypoint(routePlan.endSymbol).type;
      final arrival = approximateDuration(timeLeft);
      logger.info('  enroute to $destination $destinationType in $arrival');
    }
  }

  logger.info(
    '\n${plural(systemsToWatch.length, 'system')} '
    'with at least 5 markets:',
  );
  for (final systemSymbol in systemsToWatch) {
    final shipsAssigned = systemWatcherStates
        .where((s) => s.systemWatcherJob?.systemSymbol == systemSymbol)
        .map((s) => s.shipSymbol)
        .toList();
    logger.info(
      '${systemSymbol.systemName.padRight(4)} has '
      '${plural(shipsAssigned.length, 'watcher')}',
    );
  }
}
