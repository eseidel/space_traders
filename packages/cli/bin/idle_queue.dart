import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/idle_queue.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);
  final caches = await Caches.loadOrFetch(fs, api, db);

  final systemSymbol = caches.agent.headquartersSystemSymbol;
  final queue = IdleQueue()..queueSystem(systemSymbol, jumpDistance: 0);
  const printEvery = 100;
  var count = 0;
  while (!queue.isDone) {
    if (count++ % printEvery == 0) {
      logger.info('$queue');
    }
    await queue.runOne(db, api, caches);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
