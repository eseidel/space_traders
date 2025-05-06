import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';
import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}

int _costOutMounts(MarketPriceSnapshot marketPrices, MountSymbolSet mounts) {
  return mounts.fold<int>(
    0,
    (previousValue, mountSymbol) =>
        previousValue +
        marketPrices.medianPurchasePrice(
          tradeSymbolForMountSymbol(mountSymbol),
        )!,
  );
}

/// Returns a map of ship frame type to count in fleet.
Map<ShipType, int> _shipTypeCounts(
  ShipyardShipSnapshot shipyardShips,
  List<Ship> ships,
) {
  final typeCounts = <ShipType, int>{};
  for (final ship in ships) {
    final type = shipyardShips.guessShipType(ship)!;
    typeCounts[type] = (typeCounts[type] ?? 0) + 1;
  }
  return typeCounts;
}

Future<void> command(Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  final shipyardShips = await ShipyardShipCache(db).snapshot();

  logger.info('Estimating fleet value at current median prices.');

  // Include all ships now that scrapping is a thing.
  final purchasedShips = ships.ships;
  final purchaseShipTypes =
      purchasedShips.map((s) => shipyardShips.guessShipType(s)!).toList();
  final purchaseShipTypeCounts = _shipTypeCounts(shipyardShips, purchasedShips);
  final shipTypes =
      purchaseShipTypeCounts.keys.toList()..sortBy((t) => t.value);
  for (final type in shipTypes) {
    final price = shipyardPrices.medianPurchasePrice(type);
    final priceString = price == null ? '???' : creditsString(price);
    logger.info('${purchaseShipTypeCounts[type]} $type @ $priceString each');
  }

  // Purchase price != scrapping price, so this is wrong.
  final totalShipCost =
      purchaseShipTypes
          .map((t) => shipyardPrices.medianPurchasePrice(t) ?? 0)
          .sum;
  logger.info('Ships: ${creditsString(totalShipCost)}');

  // Mount costs
  final totalMountCost =
      purchasedShips.map((ship) {
        if (!ship.isMiner) return 0;
        final mounts = ship.mountedMountSymbols;
        return _costOutMounts(marketPrices, mounts);
      }).sum;
  logger.info('Mounts: ${creditsString(totalMountCost)}');

  final totalCost = totalShipCost + totalMountCost;
  logger.info('Total: ${creditsString(totalCost)}');
}
