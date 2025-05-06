import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final api = await defaultApi(db);
  // Ask the API how many systems and waypoints there are in total.
  final status = await api.defaultApi.getStatus();
  final stats = status!.stats;
  logger
    ..info('Waypoints: ${stats.waypoints}')
    ..info('Systems: ${stats.systems}');
  // Check to see if we already the systems and waypoints tables.
  // If we do, we're done.
  // Otherwise, download the systems.json file and import it.
}

void main(List<String> args) {
  runOffline(args, command);
}
