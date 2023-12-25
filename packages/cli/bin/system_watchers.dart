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

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final tradeGoodCache = TradeGoodCache.load(fs);
  final marketListingCache = MarketListingCache.load(fs, tradeGoodCache);
  final systemsToWatch = marketListingCache.systemsWithAtLeastNMarkets(5);

  final behaviorCache = BehaviorCache.load(fs);
  final systemWatcherStates =
      behaviorCache.states.where((s) => s.behavior == Behavior.systemWatcher);
  final systemsCache = SystemsCache.load(fs)!;
  // final marketPrices = MarketPrices.load(fs);
  final shipCache = ShipCache.load(fs)!;

  for (final state in systemWatcherStates) {
    final shipSymbol = state.shipSymbol;
    final assignedSystem = state.systemWatcherJob?.systemSymbol;
    final ship = shipCache[shipSymbol];
    final navString = describeShipNav(ship.nav);
    logger.info('${ship.emojiName} assigned to $assignedSystem, $navString');

    final routePlan = state.routePlan;
    if (routePlan != null) {
      final timeLeft = ship.timeToArrival(routePlan);
      final destination = routePlan.endSymbol.sectorLocalName;
      final destinationType = systemsCache.waypoint(routePlan.endSymbol).type;
      final arrival = approximateDuration(timeLeft);
      logger.info('  enroute to $destination $destinationType in $arrival');
    }
  }

  for (final systemSymbol in systemsToWatch) {
    final shipsAssigned = systemWatcherStates
        .where((s) => s.systemWatcherJob?.systemSymbol == systemSymbol)
        .map((s) => s.shipSymbol)
        .toList();
    logger.info(
      'system $systemSymbol has ${shipsAssigned.length} watchers assigned',
    );
  }
}
