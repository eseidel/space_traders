import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/net/auth.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final startSystemSymbol = await startSystemFromArg(
    db,
    argResults.rest.firstOrNull,
  );

  final api = await defaultApi(db, getPriority: () => networkPriorityLow);

  final systemsCache = await db.snapshotAllSystems();
  final jumpGateSymbol =
      systemsCache
          .waypointsInSystem(startSystemSymbol)
          .firstWhere((w) => w.isJumpGate)
          .symbol;

  final constructionCache = ConstructionCache(db);
  final jumpGate = await getOrFetchJumpGate(db, api, jumpGateSymbol);

  Future<String> statusForSymbol(WaypointSymbol symbol) async =>
      constructionStatusString(await constructionCache.getRecord(symbol));

  logger.info('$jumpGateSymbol: ${await statusForSymbol(jumpGateSymbol)}');
  for (final connection in jumpGate.connections) {
    final status = await statusForSymbol(connection);
    logger.info('  ${connection.sectorLocalName.padRight(9)} $status');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
