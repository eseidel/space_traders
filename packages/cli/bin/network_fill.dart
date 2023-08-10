import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final connection = await defaultDatabase();
  final queue = NetQueue(connection!, QueueRole.requestor);

  final requests = [
    (3, 'https://api.spacetraders.io/v2/my/3'),
    (2, 'https://api.spacetraders.io/v2/my/2'),
    (1, 'https://api.spacetraders.io/v2/my/1'),
    (3, 'https://api.spacetraders.io/v2/my/3'),
    (2, 'https://api.spacetraders.io/v2/my/2'),
    (1, 'https://api.spacetraders.io/v2/my/1'),
  ];

  // We don't yet have support for waiting on multiple requests, so sending
  // one at a time.
  for (final request in requests) {
    final response =
        await queue.sendAndWait(request.$1, QueuedRequest.empty(request.$2));
    logger.info('Got response: ${response.statusCode} ${response.body}');
  }

  await connection.close();
  logger.info('Done!');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
