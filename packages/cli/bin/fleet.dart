import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

String _shipStatusLine(Ship ship, SystemsCache systemsCache) {
  final waypoint = systemsCache.waypointFromSymbol(ship.waypointSymbol);
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

void logShip(
  SystemsCache systemsCache,
  BehaviorCache behaviorCache,
  MarketPrices marketPrices,
  SystemConnectivity systemConnectivity,
  JumpCache jumpCache,
  Ship ship,
) {
  final behavior = behaviorCache.getBehavior(ship.shipSymbol);
  logger
    ..info('${ship.symbol}: ${behavior?.behavior}')
    ..info('  ${_shipStatusLine(ship, systemsCache)}');
  if (ship.cargo.isNotEmpty) {
    logger.info(
      describeInventory(marketPrices, ship.cargo.inventory, indent: '  '),
    );
  }
  final routePlan = behavior?.routePlan;
  if (routePlan != null) {
    final timeLeft = timeToArrival(systemsCache, routePlan, ship);
    final destination = routePlan.endSymbol;
    final arrival = approximateDuration(timeLeft);
    logger.info('  destination: $destination, '
        'arrives in $arrival');
  }
  final deal = behavior?.deal;
  if (deal != null) {
    logger.info('  ${describeCostedDeal(deal)}');
    final since = DateTime.timestamp().difference(deal.startTime);
    logger.info(' duration: ${approximateDuration(since)}');
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
  final shipCache = ShipCache.loadCached(fs)!;

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

  final systemsCache = SystemsCache.loadCached(fs)!;
  final marketPrices = MarketPrices.load(fs);
  final systemConnectivity = SystemConnectivity.fromSystemsCache(systemsCache);
  final jumpCache = JumpCache();
  for (final ship in matchingShips) {
    logShip(
      systemsCache,
      behaviorCache,
      marketPrices,
      systemConnectivity,
      jumpCache,
      ship,
    );
  }
}