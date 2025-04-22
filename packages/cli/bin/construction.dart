import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';

// TODO(eseidel): Is this still needed after jumpgate.dart?
Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol = await startSystemFromArg(
    db,
    argResults.rest.firstOrNull,
  );

  final systemsCache = SystemsCache.load(fs);
  final jumpGateSymbol =
      systemsCache
          .waypointsInSystem(startSystemSymbol)
          .firstWhere((w) => w.isJumpGate)
          .symbol;

  final constructionCache = ConstructionCache(db);
  final construction = await constructionCache.getConstruction(jumpGateSymbol);
  logger.info('$jumpGateSymbol: ${constructionStatusString(construction)}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
