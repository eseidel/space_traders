import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final systems = await db.systems.snapshot();

  // Find all known reachable systems.
  // List ones we know are reachable but don't have any prices.
  final interestingSystemSymbols = findInterestingSystems(systems);
  logger.info(
    'Found ${interestingSystemSymbols.length} '
    'interesting systems.',
  );

  for (final symbol in interestingSystemSymbols) {
    final waypoints = systems.waypointsInSystem(symbol);
    logger.info('Fetched ${waypoints.length} waypoints for $symbol.');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
