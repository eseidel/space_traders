import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/plan/accounting.dart';
import 'package:cli/plan/ships.dart';
import 'package:collection/collection.dart';

class Assets {
  Assets({
    required this.cash,
    required this.inventory,
    required this.ships,
  });
  final int cash;
  final int inventory;
  final int ships;

  int get total => cash + inventory + ships;
}

Future<int> computeShipValue(
  ShipSnapshot ships,
  ShipyardShipCache shipyardShips,
  ShipyardPriceSnapshot shipyardPrices,
) async {
  ShipType shipTypeForShip(Ship ship) {
    final type = guessShipType(shipyardShips, ship);
    if (type == null) {
      throw StateError('Unknown ship type for frame: ${ship.frame.symbol}');
    }
    return type;
  }

  // Ignoring the first two ships, since they come for free.
  final purchasedShips = ships.ships.skip(2).toList();
  final purchaseShipTypes = purchasedShips.map(shipTypeForShip).toList();
  final totalShipCost =
      purchaseShipTypes.map((s) => shipyardPrices.medianPurchasePrice(s)!).sum;

  // TODO(eseidel): Should we count all mount value or just ones which differ
  // from stock?  For now doing neither.

  return totalShipCost;
}

Future<Assets> computeAssets(FileSystem fs, Database db) async {
  final ships = await ShipSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  final shipyardShips = ShipyardShipCache.load(fs);

  final agent = await db.getMyAgent();
  final inventory = await computeInventoryValue(ships, marketPrices);
  final shipsValue =
      await computeShipValue(ships, shipyardShips, shipyardPrices);

  return Assets(cash: agent!.credits, inventory: inventory, ships: shipsValue);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final assets = await computeAssets(fs, db);

  String c(int credits) => creditsString(credits);

  logger
    ..info('ASSETS')
    ..info('Current Assets')
    ..info('  Cash: ${c(assets.cash)}')
    ..info('  Inventory: ${c(assets.inventory)}')
    ..info('Fixed Assets')
    ..info('  Ships: ${c(assets.ships)}')
    ..info('Total Assets: ${c(assets.total)}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
