import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';
// Go buy and deliver.
// Used for modules.

/// Calculated trip cost of going and buying something.
class CostedTrip {
  /// Create a new costed trip.
  CostedTrip({required this.route, required this.price});

  /// The route to get there.
  final RoutePlan route;

  /// The historical price for the item at a given market.
  final MarketPrice price;
}

/// Compute the cost of going to and buying from a specific MarketPrice record.
CostedTrip? costTrip(
  Ship ship,
  RoutePlanner planner,
  MarketPrice price,
  WaypointSymbol start,
  WaypointSymbol end,
) {
  final route = planner.planRoute(
    start: start,
    end: end,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  if (route == null) {
    return null;
  }
  return CostedTrip(route: route, price: price);
}

/// Find the best market to buy a given item from.
CostedTrip? findBestMarketToBuy(
  MarketPrices marketPrices,
  RoutePlanner routePlanner,
  Ship ship,
  TradeSymbol tradeSymbol,
) {
  final prices = marketPrices.pricesFor(tradeSymbol).toList();
  if (prices.isEmpty) {
    return null;
  }
  final start = ship.waypointSymbol;

  // If there are a lot f prices we could cut down the search space by only
  // looking at prices at or below median?
  // final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
  // Find the closest 10 prices which are median or below.
  // final medianOrBelow = prices.where((e) => e.purchasePrice <= medianPrice);

  final costed = <CostedTrip>[];
  for (final price in prices) {
    final end = price.waypointSymbol;
    final trip = costTrip(ship, routePlanner, price, start, end);
    if (trip != null) {
      costed.add(trip);
    } else {
      logger.warn('No route from $start to $end');
    }
  }

  final sorted = costed.toList()
    ..sort((a, b) => a.route.duration.compareTo(b.route.duration));

  final nearest = sorted.first;
  if (sorted.length == 1) {
    return nearest;
  }

  // Have a set time value of money (e.g. 7c/s)
  const expectedCreditsPerSecond = 7;

  var best = nearest;
  // Pick any one further that saves more than 7c/s
  for (final trip in sorted.sublist(1)) {
    final priceDiff = trip.price.purchasePrice - nearest.price.purchasePrice;
    final savings = -priceDiff;
    final extraTime = trip.route.duration - nearest.route.duration;
    final savingsPerSecond = savings / extraTime.inSeconds;
    if (savingsPerSecond > expectedCreditsPerSecond) {
      best = trip;
      break;
    }
  }

  return best;
}

// class _BuyJob {
//   _BuyJob({
//     required this.tradeSymbol,
//     required this.units,
//     required this.route,
//   });

//   final String tradeSymbol;
//   final int units;
//   final RoutePlan route;
// }

// class _DeliverJob {
//   _DeliverJob({
//     required this.tradeSymbol,
//     required this.shipSymbol,
//     required this.units,
//     required this.route,
//   });
//   final String tradeSymbol;
//   final String shipSymbol;
//   final int units;
//   final RoutePlan route;
// }

/// Compute the trade symbol for the given mount symbol.
TradeSymbol? tradeSymbolForMountSymbol(ShipMountSymbolEnum mountSymbol) {
  return TradeSymbol.fromJson(mountSymbol.value);
}

/// Compute the mount symbol for the given trade symbol.
ShipMountSymbolEnum? mountSymbolForTradeSymbol(TradeSymbol tradeSymbol) {
  return ShipMountSymbolEnum.fromJson(tradeSymbol.value);
}

/// Compute the mounts in the given ship's inventory.
Map<ShipMountSymbolEnum, int> countMountsInInventory(Ship ship) {
  final counts = <ShipMountSymbolEnum, int>{};
  for (final item in ship.cargo.inventory) {
    final mountSymbol = mountSymbolForTradeSymbol(item.tradeSymbol);
    if (mountSymbol == null) {
      continue;
    }
    final count = counts[mountSymbol] ?? 0;
    counts[mountSymbol] = count + item.units;
  }
  return counts;
}

/// Compute the mounts mounted on the given ship.
Map<ShipMountSymbolEnum, int> countMountedMounts(Ship ship) {
  final counts = <ShipMountSymbolEnum, int>{};
  for (final mount in ship.mounts) {
    final count = counts[mount.symbol] ?? 0;
    counts[mount.symbol] = count + 1;
  }
  return counts;
}

/// Compute the mounts needed to make the given ship match the given template.
Map<ShipMountSymbolEnum, int> mountsNeededForShip(
  Ship ship,
  ShipTemplate template,
) {
  final needed = <ShipMountSymbolEnum, int>{};
  final existing = countMountedMounts(ship);
  for (final mountSymbol in template.mounts.keys) {
    final neededCount = template.mounts[mountSymbol]!;
    final existingCount = existing[mountSymbol] ?? 0;
    final neededMounts = neededCount - existingCount;
    if (neededMounts > 0) {
      needed[mountSymbol] = neededMounts;
    }
  }
  return needed;
}

Map<ShipMountSymbolEnum, int> _mountsNeededForAllShips(
  CentralCommand centralCommand,
  ShipCache shipCache,
) {
  final needed = <ShipMountSymbolEnum, int>{};
  for (final ship in shipCache.ships) {
    final template = centralCommand.templateForShip(ship);
    if (template == null) {
      continue;
    }
    for (final entry in mountsNeededForShip(ship, template).entries) {
      final mountSymbol = entry.key;
      final neededCount = entry.value;
      final existingCount = needed[mountSymbol] ?? 0;
      needed[mountSymbol] = existingCount + neededCount;
    }
  }
  return needed;
}

class _BuyRequest {
  _BuyRequest({
    required this.tradeSymbol,
    required this.units,
  });

  final TradeSymbol tradeSymbol;
  final int units;
}

_BuyRequest? _buyRequestFromNeededMounts(Map<ShipMountSymbolEnum, int> needed) {
  if (needed.isEmpty) {
    return null;
  }
  // Check each of the needed mounts for availability and affordability.

  final mountSymbol = needed.keys.first;
  final units = needed[mountSymbol]!;
  final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol)!;
  return _BuyRequest(tradeSymbol: tradeSymbol, units: units);
}

/// Advance the behavior of the given ship.
Future<DateTime?> advanceDeliver(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // Figure out if there are any things needing to be delivered.
  // Look at our ore-hounds, see if they are matching spec.
  // If mounts are missing, see if we can buy them.
  final neededMounts = _mountsNeededForAllShips(centralCommand, caches.ships);
  if (neededMounts.isEmpty) {
    centralCommand.disableBehaviorForShip(
      ship,
      Behavior.deliver,
      'No mounts needed.',
      const Duration(minutes: 20),
    );
    return null;
  }

  // Figure out what item we're supposed to get.
  // If so, in what priority?
  // If we can't buy them, disable the behavior for a while.
  final buyRequest = _buyRequestFromNeededMounts(neededMounts);
  if (buyRequest == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      Behavior.deliver,
      'No mounts available.',
      const Duration(minutes: 20),
    );
    return null;
  }

  final tradeSymbol = buyRequest.tradeSymbol;
  final maxToBuy = buyRequest.units;

  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyard = hqWaypoints.firstWhereOrNull((w) => w.hasShipyard);
  if (shipyard == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      Behavior.deliver,
      'No shipyard in $hqSystem',
      const Duration(days: 1),
    );
    return null;
  }

  final haveItem = ship.countUnits(tradeSymbol) > 0;
  final atDelivery = ship.waypointSymbol == shipyard.waypointSymbol;

  if (!haveItem) {
    // Find the best place to buy it.
    final trip = findBestMarketToBuy(
      caches.marketPrices,
      caches.routePlanner,
      ship,
      tradeSymbol,
    );
    if (trip == null) {
      centralCommand.disableBehaviorForShip(
        ship,
        Behavior.deliver,
        'No market for $tradeSymbol',
        const Duration(days: 1),
      );
      return null;
    }

    // Go there.
    return beingRouteAndLog(
      api,
      ship,
      caches.systems,
      centralCommand,
      trip.route,
    );
  }

  if (atDelivery) {
    centralCommand
      ..completeBehavior(ship.shipSymbol)
      ..setBehavior(
        ship.shipSymbol,
        BehaviorState(ship.shipSymbol, Behavior.idle),
      );
    return null;
  }

  // Otherwise we're at our buy location.
  await purchaseCargoAndLog(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    ship,
    tradeSymbol,
    maxToBuy,
    AccountingType.capital,
  );
  // And go to our destination.
  final waitUntil = await beingNewRouteAndLog(
    api,
    ship,
    caches.systems,
    caches.routePlanner,
    centralCommand,
    shipyard.waypointSymbol,
  );
  return waitUntil;
}

// This seems related to using haulers for delivery of trade goods.
// They get loaded by miners.
// Then their job is how to figure out where to sell it.
// If there isn't a hauler to load to, the miner just sells?
// If the hauler isn't full it just sleeps until full?
