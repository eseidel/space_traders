import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/deliver.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final behaviorCache = BehaviorCache.load(fs);
  final centralCommand =
      CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);

  for (final ship in shipCache.ships) {
    final template = centralCommand.templateForShip(ship);
    if (template == null) {
      logger.info('No template for ${ship.symbol}.');
      continue;
    }
    final needed = mountsNeededForShip(ship, template);
    if (needed.isEmpty) {
      logger.info('No mounts needed for ${ship.symbol}.');
      continue;
    }
    for (final mountSymbol in needed.distinct) {
      final units = needed[mountSymbol];
      logger.info('Need $units $mountSymbol for ${ship.symbol}.');
    }
  }

  final mounts = centralCommand.mountsNeededForAllShips();
  if (mounts.isEmpty) {
    logger.info('No mounts needed.');
    return;
  }
  for (final mountSymbol in mounts.distinct) {
    final units = mounts[mountSymbol];
    logger.info('Need $units $mountSymbol.');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
