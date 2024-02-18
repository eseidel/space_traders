import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final shipCache = ShipCache.load(fs)!;
  final shipyardPrices = await ShipyardPrices.load(db);
  final shipyardShips = ShipyardShipCache.load(fs);

  final shipType = shipToBuyFromPlan(
    shipCache,
    config.buyPlan,
    shipyardPrices,
    shipyardShips,
  );
  if (shipType == null) {
    logger.info('No ship to buy.');
    return;
  }
  logger.info('Buy $shipType.');
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
