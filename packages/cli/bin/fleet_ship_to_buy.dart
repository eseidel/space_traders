import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final shipCache = await ShipSnapshot.load(db);
  final shipyardListings = await ShipyardListingSnapshot.load(db);
  final shipyardShips = await ShipyardShipCache(db).snapshot();

  final shipType = await shipToBuyFromPlan(
    shipCache,
    config.buyPlan,
    shipyardListings,
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
