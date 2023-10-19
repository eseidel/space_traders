import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final behaviorCache = BehaviorCache.load(fs);
  final centralCommand =
      CentralCommand(shipCache: shipCache, behaviorCache: behaviorCache);
  final squads = centralCommand.miningSquads.toList();
  logger.info('${squads.length} squads');
  for (var i = 0; i < squads.length; i++) {
    final squad = squads[i];
    logger.info('Squad $i:');
    for (final ship in squad.ships) {
      logger.info(
        '  ${ship.symbol} ${ship.frame.symbol} ${ship.mountedMountSymbols}',
      );
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
