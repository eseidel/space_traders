import 'dart:io';

import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';

// We can delete this command once we have multiple processes.
Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final queue = NetQueue(db, QueueRole.requestor);

  while (true) {
    final _ = await queue.sendAndWait(
      // Low priority.
      -1,
      QueuedRequest.empty('https://api.spacetraders.io/v2'),
    );
    stdout.write('.');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
