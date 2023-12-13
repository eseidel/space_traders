import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final jumpGateCache = JumpGateCache.load(fs);
  final shipCache = ShipCache.load(fs)!;

  final brokenGates = jumpGateCache.values.where((r) => r.isBroken);

  logger.info('Found ${brokenGates.length} broken jumpgates:');
  for (final record in brokenGates) {
    final systemSymbol = record.waypointSymbol.systemSymbol;
    final trapped =
        shipCache.ships.where((s) => s.systemSymbol == systemSymbol).toList();
    logger.info('${record.waypointSymbol}: ${describeShips(trapped)} trapped');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
