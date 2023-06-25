import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  logger.info(describeFleet(caches.ships));
  final ships = caches.ships.ships;
  for (final ship in ships) {
    logger.info(shipDescription(ship, caches.systems));
  }
}
