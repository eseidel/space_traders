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
  _printMissing(ShipMountSymbolEnum.values, await db.shipMounts.snapshot());
  _printMissing(ShipModuleSymbolEnum.values, await db.shipModules.snapshot());
  _printMissing(ShipType.values, await db.shipyardShips.snapshot());
  _printMissing(ShipEngineSymbolEnum.values, await db.shipEngines.snapshot());
  _printMissing(ShipReactorSymbolEnum.values, await db.shipReactors.snapshot());
  _printMissing(WaypointTraitSymbol.values, await db.waypointTraits.snapshot());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
