import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/ships.dart';
import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}

int _costOutMounts(
  MarketPriceSnapshot marketPrices,
  MountSymbolSet mounts,
) {
  return mounts.fold<int>(
    0,
    (previousValue, mountSymbol) =>
        previousValue +
        marketPrices
            .medianPurchasePrice(tradeSymbolForMountSymbol(mountSymbol))!,
  );
}

/// Returns a map of ship frame type to count in fleet.
Map<ShipType, int> _shipTypeCounts(
  ShipyardShipCache shipyardShips,
  List<Ship> ships,
) {
  final typeCounts = <ShipType, int>{};
  for (final ship in ships) {
    final type = shipyardShips.shipTypeFromFrame(ship.frame.symbol)!;
    typeCounts[type] = (typeCounts[type] ?? 0) + 1;
  }
  return typeCounts;
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.load(db);
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  final shipyardShips = ShipyardShipCache.load(fs);

  logger
    ..info('Estimating fleet value at current median prices.')
    ..info('Excluding initial ships.');

  final purchasedShips = ships.ships.skip(2).toList();
  final purchaseShipTypes = purchasedShips
      .map((s) => shipyardShips.shipTypeFromFrame(s.frame.symbol)!)
      .toList();
  final purchaseShipTypeCounts = _shipTypeCounts(shipyardShips, purchasedShips);
  final shipTypes = purchaseShipTypeCounts.keys.toList()
    ..sortBy((t) => t.value);
  for (final type in shipTypes) {
    logger.info('${purchaseShipTypeCounts[type]} $type @ '
        '${creditsString(shipyardPrices.medianPurchasePrice(type)!)}');
  }

  final totalShipCost =
      purchaseShipTypes.map((t) => shipyardPrices.medianPurchasePrice(t)!).sum;
  logger.info('Ships: ${creditsString(totalShipCost)}');

  // Mount costs
  final totalMountCost = purchasedShips.map((ship) {
    if (!ship.isMiner) return 0;
    final mounts = ship.mountedMountSymbols;
    return _costOutMounts(marketPrices, mounts);
  }).sum;
  logger.info('Mounts: ${creditsString(totalMountCost)}');

  final totalCost = totalShipCost + totalMountCost;
  logger.info('Total: ${creditsString(totalCost)}');
}
