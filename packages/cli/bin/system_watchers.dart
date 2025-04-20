import 'package:cli/behavior/system_watcher.dart';
import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/trading.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

// Could share with fleet.dart
void logShip(
  SystemsCache systemsCache,
  MarketPriceSnapshot marketPrices,
  Ship ship,
  BehaviorState? behavior,
) {
  const indent = '   ';
  final waypoint = systemsCache.waypoint(ship.waypointSymbol);
  logger.info(ship.symbol.hexNumber);

  final routePlan = behavior?.routePlan;
  if (routePlan != null) {
    final timeLeft = ship.timeToArrival(routePlan);
    final destination = routePlan.endSymbol.sectorLocalName;
    final destinationType = systemsCache.waypoint(routePlan.endSymbol).type;
    final arrival = approximateDuration(timeLeft);
    logger.info(
      '${indent}en route to $destination $destinationType '
      'in $arrival',
    );
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

  final systemWatcherStates = await db.behaviorStatesWithBehavior(
    Behavior.systemWatcher,
  );
  final systemsCache = SystemsCache.load(fs);
  final ships = await ShipSnapshot.load(db);
  final agentCache = await AgentCache.load(db);

  final systemConnectivity = await loadSystemConnectivity(db);
  final hqSystemSymbol = agentCache!.headquartersSystemSymbol;

  logger.info('${plural(systemWatcherStates.length, 'watcher')} assigned:');
  for (final state in systemWatcherStates) {
    final shipSymbol = state.shipSymbol;
    final assignedSystemName = state.systemWatcherJob?.systemSymbol.systemName
        .padRight(4);
    final ship = ships[shipSymbol];
    final navString = describeShipNav(ship!.nav);
    logger.info(
      '${ship.emojiName} assigned to $assignedSystemName, $navString',
    );

    final routePlan = state.routePlan;
    if (routePlan != null) {
      final timeLeft = ship.timeToArrival(routePlan);
      final destination = routePlan.endSymbol.sectorLocalName;
      final destinationType = systemsCache.waypoint(routePlan.endSymbol).type;
      final arrival = approximateDuration(timeLeft);
      logger.info('  en route to $destination $destinationType in $arrival');
    }
  }

  logger.info(
    '\n${plural(systemsToWatch.length, 'system')} '
    'with at least 5 markets:',
  );
  final unreachableSystems = <SystemSymbol>{};

  for (final systemSymbol in systemsToWatch) {
    final shipsAssigned =
        systemWatcherStates
            .where((s) => s.systemWatcherJob?.systemSymbol == systemSymbol)
            .map((s) => s.shipSymbol)
            .toList();
    if (shipsAssigned.isEmpty &&
        !systemConnectivity.existsJumpPathBetween(
          systemSymbol,
          hqSystemSymbol,
        )) {
      unreachableSystems.add(systemSymbol);
      continue;
    }
    logger.info(
      '${systemSymbol.systemName.padRight(4)} has '
      '${plural(shipsAssigned.length, 'watcher')}',
    );
  }

  if (unreachableSystems.isNotEmpty) {
    logger.info('\n${plural(unreachableSystems.length, 'unreachable system')}');
  }

  logger.info('Assignments:');
  final assignments = assignProbesToSystems(
    systemConnectivity,
    marketListings,
    ships,
  );
  for (final entry in assignments.entries) {
    final clusterId = systemConnectivity.clusterIdForSystem(entry.value);
    logger.info(
      '${entry.value.systemName.padRight(4)}: ${entry.key} ($clusterId)',
    );
  }
}
