import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final systemsCache = SystemsCache.load(fs);

  for (final system in systemsCache.systems) {
    if (system.)
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
