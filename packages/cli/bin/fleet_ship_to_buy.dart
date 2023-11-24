import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipCache = ShipCache.load(fs)!;
  final shipyardPrices = ShipyardPrices.load(fs);
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
