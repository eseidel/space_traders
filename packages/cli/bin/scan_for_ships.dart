import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.waypoints, myShips);

  final scanResponse = await api.fleet.createShipShipScan(ship.symbol);
  final scan = scanResponse!.data;
  logger.info('Scanned ${scan.ships.length} ships.');
  prettyPrintJson(scan.toJson());
}
