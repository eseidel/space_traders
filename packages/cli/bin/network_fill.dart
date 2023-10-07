import 'dart:io';

import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';

// We can delete this command once we have multiple processes.
Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final queue = NetQueue(db, QueueRole.requestor);

  while (true) {
    final _ = await queue.sendAndWait(
      // Low prioirty.
      -1,
      QueuedRequest.empty('https://api.spacetraders.io/v2'),
    );
    stdout.write('.');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
