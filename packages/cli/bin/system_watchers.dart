import 'package:cli/behavior/system_watcher.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/trading.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

// Could share with fleet.dart
Future<void> logShip(
  Database db,
  MarketPriceSnapshot marketPrices,
  Ship ship,
  BehaviorState? behavior,
) async {
  const indent = '   ';
  final waypoint = await db.systems.waypoint(ship.waypointSymbol);
  logger.info(ship.symbol.hexNumber);

  final routePlan = behavior?.routePlan;
  if (routePlan != null) {
    final timeLeft = ship.timeToArrival(routePlan);
    final destination = routePlan.endSymbol.sectorLocalName;
    final destinationType = await db.systems.waypointType(routePlan.endSymbol);
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

Future<void> command(Database db, ArgResults argResults) async {
  final marketListings = await db.marketListings.snapshotAll();
  final systemsToWatch = marketListings.systemsWithAtLeastNMarkets(5);

  final systemWatcherStates = await db.behaviorsOfType(Behavior.systemWatcher);
  final systemsCache = db.systems;
  final ships = await ShipSnapshot.load(db);
  final agent = await db.getMyAgent();

  final systemConnectivity = await loadSystemConnectivity(db);
  final hqSystemSymbol = agent!.headquarters.system;

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
      final destinationType = await systemsCache.waypointType(
        routePlan.endSymbol,
      );
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
