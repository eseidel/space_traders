import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/idle_queue.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);
  final caches = await Caches.loadOrFetch(fs, api, db);

  final systemSymbol = caches.agent.headquartersSystemSymbol;
  final queue = IdleQueue()..queueSystem(systemSymbol, jumpDistance: 0);
  while (!queue.isDone) {
    await queue.runOne(api, caches);
  }

  // required or main() will hang
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
