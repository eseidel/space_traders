import 'package:cli/cli.dart';
import 'package:cli/net/queue.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final queue = NetQueue();

  final requests = [
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/3', 3),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/2', 2),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/1', 1),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/3', 3),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/2', 2),
    QueuedRequest.empty('https://api.spacetraders.io/v2/my/1', 1),
  ];

  // We don't yet have support for waiting on multiple requests, so sending
  // one at a time.
  for (final request in requests) {
    final response = await queue.sendAndWait(request);
    logger.info('Got response: ${response.statusCode} ${response.body}');
  }

  await queue.disconnect();
  logger.info('Done!');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
