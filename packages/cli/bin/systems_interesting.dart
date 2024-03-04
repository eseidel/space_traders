import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final systemsCache = SystemsCache.load(fs)!;
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateSnapshot, constructionSnapshot);
  final hqSystemSymbol = await myHqSystemSymbol(db);
  final reachableSystems =
      systemConnectivity.systemsReachableFrom(hqSystemSymbol).toSet();

  // Find all known reachable systems.
  // List ones we know are reachable but don't have any prices.
  final interestingSystemSymbols = findInterestingSystems(systemsCache);
  final reachableInterestingSystemSymbols =
      reachableSystems.intersection(interestingSystemSymbols);
  logger.info(
    'Found ${reachableInterestingSystemSymbols.length} reachable '
    'interesting systems:',
  );
  for (final symbol in reachableInterestingSystemSymbols) {
    logger.info('$symbol');
  }
  logger.info('of ${interestingSystemSymbols.length} interesting systems.');

  final reachableJumpGates = jumpGateSnapshot.values.where(
    (record) => reachableSystems.contains(record.waypointSymbol.system),
  );
  // These are not necessarily reachable (the jump gate on either side might
  // be under construction).
  final connectedSystemSymbols = reachableJumpGates
      .map((record) => record.connectedSystemSymbols)
      .expand((e) => e)
      .toSet();

  // Number of under construction waypoints we know about:
  final underConstruction = constructionSnapshot.records
      .where((record) => record.isUnderConstruction)
      .map((record) => record.waypointSymbol.system)
      .toSet();
  final connectedUnderConstruction = underConstruction.intersection(
    connectedSystemSymbols,
  );
  final total = underConstruction.length;
  logger.info(
    '${connectedUnderConstruction.length} of $total under construction '
    'jumpgates are connected to jumpgates reachable from HQ.',
  );
}

void main(List<String> args) async {
  await runOffline(args, command);
}
