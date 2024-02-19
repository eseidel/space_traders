import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final behaviorCache = await BehaviorCache.load(db);

  final shipSymbols = behaviorCache.states
      .where((s) => s.behavior == Behavior.systemWatcher)
      .map((s) => s.shipSymbol)
      .toSet();

  if (shipSymbols.isEmpty) {
    logger.info('No system watchers to clear.');
    return;
  }
  logger.info('Clearing ${shipSymbols.length} system watchers...');
  for (final shipSymbol in shipSymbols) {
    await behaviorCache.deleteBehavior(shipSymbol);
  }
}
