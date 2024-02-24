import 'dart:math';

import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final shipCache = await ShipSnapshot.load(db);
  final behaviorCache = await BehaviorCache.load(db);
  final centralCommand =
      CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);

  final symbolWidth =
      ShipMountSymbolEnum.values.fold(0, (s, e) => max(s, e.value.length)) + 1;

  // Must be called before we can call templateForShip.
  await centralCommand.updateAvailableMounts(db);

  for (final ship in shipCache.ships) {
    final template = centralCommand.templateForShip(ship);
    if (template == null) {
      logger.detail('No template for ${ship.symbol}.');
      continue;
    }
    final needed = mountsToAddToShip(ship, template);
    if (needed.isEmpty) {
      logger.detail('No mounts to add to ${ship.symbol}.');
    } else {
      for (final mountSymbol in needed.distinct) {
        final units = needed[mountSymbol];
        logger.info(
          '+$units '
          '${mountSymbol.value.padRight(symbolWidth)} ${ship.symbol}',
        );
      }
    }
    final toRemove = mountsToRemoveFromShip(ship, template);
    if (toRemove.isEmpty) {
      logger.detail('No mounts to remove from ${ship.symbol}.');
    } else {
      for (final mountSymbol in toRemove.distinct) {
        final units = toRemove[mountSymbol];
        logger.info(
          '-$units '
          '${mountSymbol.value.padRight(symbolWidth)} ${ship.symbol}',
        );
      }
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
