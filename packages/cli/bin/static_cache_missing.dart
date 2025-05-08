import 'package:cli/cli.dart';

void _printMissing<K extends Object, V extends Object>(
  Iterable<K> symbols,
  StaticSnapshot<K, V> cache,
) {
  final missingSymbols = symbols.where((s) => cache[s] == null).toList();
  if (missingSymbols.isNotEmpty) {
    logger.info('${missingSymbols.length} missing $K:');
    for (final symbol in missingSymbols) {
      logger.info('  $symbol');
    }
  }
}

Future<void> command(Database db, ArgResults argResults) async {
  final c = StaticCaches(db);

  _printMissing(ShipMountSymbolEnum.values, await c.mounts.snapshot());
  _printMissing(ShipModuleSymbolEnum.values, await c.modules.snapshot());
  _printMissing(ShipType.values, await c.shipyardShips.snapshot());
  _printMissing(ShipEngineSymbolEnum.values, await c.engines.snapshot());
  _printMissing(ShipReactorSymbolEnum.values, await c.reactors.snapshot());
  _printMissing(WaypointTraitSymbol.values, await c.waypointTraits.snapshot());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
