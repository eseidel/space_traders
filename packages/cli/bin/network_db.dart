import 'dart:async';

import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final connection = await defaultDatabase();
  final api = defaultApi(fs, ClientType.unlimited);
  final queuedClient = QueuedClient(connection)..getPriority = () => 0;
  api.apiClient.client = queuedClient;
  final agent = await getMyAgent(api);
  logger.info('Got agent: $agent');
  queuedClient.close();
  logger.info('Done!');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
