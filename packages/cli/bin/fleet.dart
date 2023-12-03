import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

/// Returns a string representing the current navigation status of the ship.
String _describeShipNav(ShipNav nav) {
  final waypoint = nav.waypointSymbolObject.sectorLocalName;
  switch (nav.status) {
    case ShipNavStatus.DOCKED:
      return 'Docked at $waypoint';
    case ShipNavStatus.IN_ORBIT:
      return 'Orbiting $waypoint';
    case ShipNavStatus.IN_TRANSIT:
      return 'Transit to $waypoint';
  }
  return 'Unknown';
}

String describeInventory(
  MarketPrices marketPrices,
  List<ShipCargoItem> inventory, {
  String indent = '',
}) {
  final lines = <String>[];
  for (final item in inventory) {
    final symbol = item.tradeSymbol;
    final count = item.units;
    final price = marketPrices.medianSellPrice(symbol);
    final priceString = price == null ? '???' : creditsString(price);
    final valueString = price == null ? '???' : creditsString(price * count);
    lines.add(
      '$indent${symbol.value.padRight(23)} ${count.toString().padLeft(3)} x '
      '${priceString.padRight(8)} = $valueString',
    );
  }
  return lines.join('\n');
}

Duration timeToArrival(
  SystemsCache systemsCache,
  RoutePlan routePlan,
  Ship ship,
) {
  var timeLeft = ship.nav.status == ShipNavStatus.IN_TRANSIT
      ? ship.nav.route.arrival.difference(DateTime.timestamp())
      : Duration.zero;
  if (routePlan.endSymbol != ship.waypointSymbol) {
    final newPlan =
        routePlan.subPlanStartingFrom(systemsCache, ship.waypointSymbol);
    timeLeft += newPlan.duration;
    // Include cooldown until next jump.
    // We would need to keep ship cooldowns on ShipCache to do this.
    // if (newPlan.actions.first.type == RouteActionType.jump) {
    //   timeLeft += ship.jumpCooldown;
    // }
  }
  return timeLeft;
}

String _behaviorOrTypeString(Ship ship, BehaviorState? behavior) {
  if (ship.fleetRole.name == behavior?.behavior.name) {
    return ship.fleetRole.name;
  }
  // Surveyors have a single-pass loop so they sit in null commonly.
  if (ship.fleetRole == FleetRole.surveyor && behavior?.behavior == null) {
    return 'surveyor';
  }
  // No need to show the registration if it's the same as the role.
  if (ship.fleetRole.name == ship.registration.role.value.toLowerCase()) {
    return '${ship.fleetRole.name} (${behavior?.behavior.name})';
  }
  // Hauler == trader, so don't show the registration.
  if (ship.fleetRole == FleetRole.trader &&
      ship.registration.role == ShipRole.HAULER) {
    return '${ship.fleetRole.name} (${behavior?.behavior.name})';
  }
  return '${ship.fleetRole.name} (${behavior?.behavior.name}) '
      '${ship.registration.role}';
}

void logShip(
  SystemsCache systemsCache,
  BehaviorCache behaviorCache,
  MarketPrices marketPrices,
  JumpCache jumpCache,
  Ship ship,
) {
  const indent = '   ';
  final behavior = behaviorCache.getBehavior(ship.shipSymbol);
  final waypoint = systemsCache.waypoint(ship.waypointSymbol);
  final cargoStatus = ship.cargo.capacity == 0
      ? ''
      : '${ship.cargo.units}/${ship.cargo.capacity}';
  logger.info('${ship.shipSymbol.hexNumber} '
      '${_behaviorOrTypeString(ship, behavior)} $cargoStatus');
  if (ship.cargo.isNotEmpty) {
    logger.info(
      describeInventory(marketPrices, ship.cargo.inventory, indent: indent),
    );
  }
  final routePlan = behavior?.routePlan;
  if (routePlan != null) {
    final timeLeft = timeToArrival(systemsCache, routePlan, ship);
    final destination = routePlan.endSymbol.sectorLocalName;
    final arrival = approximateDuration(timeLeft);
    logger.info('${indent}in transit to $destination, '
        'arrives in $arrival');
  } else {
    logger.info('$indent${_describeShipNav(ship.nav)} ${waypoint.type}');
  }
  final deal = behavior?.deal;
  if (deal != null) {
    logger.info('$indent${describeCostedDeal(deal)}');
    final since = DateTime.timestamp().difference(deal.startTime);
    logger.info('${indent}duration: ${approximateDuration(since)}');
  }
}

bool Function(Ship) filterFromArgs(List<String> args) {
  if (args.isEmpty) {
    return (ship) => true;
  }
  final symbol = args.first;
  return (ship) => ship.symbol == symbol;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final filter = filterFromArgs(argResults.rest);
  final behaviorCache = BehaviorCache.load(fs);
  final shipCache = ShipCache.load(fs)!;

  logger.info(describeFleet(shipCache));
  final ships = shipCache.ships;
  final matchingShips = ships.where(filter).toList();
  if (matchingShips.isEmpty) {
    logger
      ..info('No ships matching ${argResults.rest.firstOrNull}.')
      ..info('Usage: list_fleet [ship_symbol]')
      ..info('Example: list_fleet ${shipCache.ships.first.symbol}');
    return;
  }

  final systemsCache = SystemsCache.load(fs)!;
  final marketPrices = MarketPrices.load(fs);
  final jumpCache = JumpCache();
  for (final ship in matchingShips) {
    logShip(
      systemsCache,
      behaviorCache,
      marketPrices,
      jumpCache,
      ship,
    );
  }

  final idleHaulers = idleHaulerSymbols(shipCache, behaviorCache)
      .map((s) => s.hexNumber)
      .toList();
  if (idleHaulers.isNotEmpty) {
    logger.info('${idleHaulers.length} idle: ${idleHaulers.join(', ')}');
  }
}
