import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';

void _printMissing<K extends Object, V extends Object>(
  Iterable<K> symbols,
  StaticCache<K, V> cache,
) {
  final missingSymbols = symbols.where((s) => cache[s] == null).toList();
  if (missingSymbols.isNotEmpty) {
    logger.info('${missingSymbols.length} missing $K:');
    for (final symbol in missingSymbols) {
      logger.info('  $symbol');
    }
  }
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final staticCaches = StaticCaches.load(fs);

  _printMissing(ShipMountSymbolEnum.values, staticCaches.mounts);
  _printMissing(ShipModuleSymbolEnum.values, staticCaches.modules);
  _printMissing(ShipType.values, staticCaches.shipyardShips);
  _printMissing(ShipEngineSymbolEnum.values, staticCaches.engines);
  _printMissing(ShipReactorSymbolEnum.values, staticCaches.reactors);
  _printMissing(WaypointTraitSymbol.values, staticCaches.waypointTraits);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
