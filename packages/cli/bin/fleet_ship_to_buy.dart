import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final shipCache = await ShipSnapshot.load(db);
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
