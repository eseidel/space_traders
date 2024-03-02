import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/trading.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

String describeInventory(
  MarketPriceSnapshot marketPrices,
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
  MarketPriceSnapshot marketPrices,
  Ship ship,
  BehaviorState? behavior,
) {
  const indent = '   ';
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

bool Function(Ship) filterFromArgs(List<String> args) {
  if (args.isEmpty) {
    return (ship) => true;
  }
  final symbol = args.first;
  return (ship) => ship.symbol == symbol;
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final filter = filterFromArgs(argResults.rest);
  final ships = await ShipSnapshot.load(db);

  logger.info('Fleet: ${describeShips(ships.ships)}');
  final matchingShips = ships.ships.where(filter).toList();
  if (matchingShips.isEmpty) {
    logger
      ..info('No ships matching ${argResults.rest.firstOrNull}.')
      ..info('Usage: list_fleet [ship_symbol]')
      ..info('Example: list_fleet ${ships.ships.first.symbol}');
    return;
  }

  final systemsCache = SystemsCache.load(fs)!;
  final marketPrices = await MarketPriceSnapshot.load(db);
  for (final ship in matchingShips) {
    final behaviorState = await db.behaviorStateBySymbol(ship.shipSymbol);
    logShip(
      systemsCache,
      marketPrices,
      ship,
      behaviorState,
    );
  }

  final behaviors = await BehaviorSnapshot.load(db);
  final idleHaulers =
      behaviors.idleHaulerSymbols(ships).map((s) => s.hexNumber).toList();
  if (idleHaulers.isNotEmpty) {
    logger.info('${idleHaulers.length} idle: ${idleHaulers.join(', ')}');
  }
}
