import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void printShipDetails(Ship ship, SystemsCache systemsCache) {
  logger.info(shipDescription(ship, systemsCache));
  logCargo(ship);

  prettyPrintJson(ship.toJson());
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.systems, myShips);
  printShipDetails(ship, caches.systems);
}
