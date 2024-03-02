import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateSymbol = systemsCache
      .waypointsInSystem(startSystemSymbol)
      .firstWhere((w) => w.isJumpGate)
      .symbol;

  final constructionSnapshot = await ConstructionSnapshot.load(db);

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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
