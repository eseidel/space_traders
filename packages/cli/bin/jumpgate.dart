import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);

  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateSymbol = systemsCache
      .waypointsInSystem(startSystemSymbol)
      .firstWhere((w) => w.isJumpGate)
      .symbol;

  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final jumpGate = await getOrFetchJumpGate(db, api, jumpGateSymbol);

  String statusString(WaypointSymbol jumpGateSymbol) {
    final isUnderConstruction =
        constructionSnapshot.isUnderConstruction(jumpGateSymbol);

    if (isUnderConstruction == null) {
      return 'unknown';
    }
    if (isUnderConstruction) {
      final construction = constructionSnapshot[jumpGateSymbol];
      final progress = describeConstructionProgress(construction);
      return 'under construction ($progress)';
    }
    return 'ready';
  }

  logger.info('$jumpGateSymbol: ${statusString(jumpGateSymbol)}');
  for (final connection in jumpGate.connections) {
    final status = statusString(connection);
    logger.info('  ${connection.sectorLocalName.padRight(9)} $status');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
