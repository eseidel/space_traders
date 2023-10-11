import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}

ShipType _shipTypeFromFrame(ShipFrameSymbolEnum frame) {
  switch (frame) {
    case ShipFrameSymbolEnum.MINER:
      return ShipType.ORE_HOUND;
    case ShipFrameSymbolEnum.DRONE:
      return ShipType.MINING_DRONE;
    case ShipFrameSymbolEnum.LIGHT_FREIGHTER:
      return ShipType.LIGHT_HAULER;
    case ShipFrameSymbolEnum.HEAVY_FREIGHTER:
      return ShipType.HEAVY_FREIGHTER;
    case ShipFrameSymbolEnum.PROBE:
    case ShipFrameSymbolEnum.INTERCEPTOR:
    case ShipFrameSymbolEnum.RACER:
    case ShipFrameSymbolEnum.FIGHTER:
    case ShipFrameSymbolEnum.FRIGATE:
    case ShipFrameSymbolEnum.SHUTTLE:
    case ShipFrameSymbolEnum.EXPLORER:
    case ShipFrameSymbolEnum.TRANSPORT:
    case ShipFrameSymbolEnum.DESTROYER:
    case ShipFrameSymbolEnum.CRUISER:
    case ShipFrameSymbolEnum.CARRIER:
  }
  throw UnimplementedError('Ship type not implemented: $frame');
}

int _costOutMounts(
  MarketPrices marketPrices,
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
Map<ShipType, int> _shipTypeCounts(List<Ship> ships) {
  final typeCounts = <ShipType, int>{};
  for (final ship in ships) {
    final type = _shipTypeFromFrame(ship.frame.symbol);
    typeCounts[type] = (typeCounts[type] ?? 0) + 1;
  }
  return typeCounts;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final marketPrices = MarketPrices.load(fs);
  final shipyardPrices = ShipyardPrices.load(fs);

  logger
    ..info('Estimating fleet value at current median prices.')
    ..info('Excluding intial ships.');

  final purchasedShips = shipCache.ships.skip(2).toList();
  final purchaseShipTypes =
      purchasedShips.map((s) => _shipTypeFromFrame(s.frame.symbol)).toList();
  final purchaseShipTypeCounts = _shipTypeCounts(purchasedShips);
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
