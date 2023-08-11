import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final db = await defaultDatabase();
  final queue = NetQueue(db, QueueRole.requestor);

  while (true) {
    final response = await queue.sendAndWait(
      // Low prioirty.
      -1,
      QueuedRequest.empty('https://api.spacetraders.io/v2'),
    );
    logger.info('Got response: ${response.statusCode} ${response.body}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
