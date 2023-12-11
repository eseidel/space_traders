import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final shipyardPrices = ShipyardPrices.load(fs);
  final waypointTraits = WaypointTraitCache.load(fs);
  final chartingCache = ChartingCache.load(fs, waypointTraits);

  // Having market price data is a good proxy for if we've explored something.
  final systemSymbols =
      marketPrices.waypointSymbols.map((e) => e.system).toSet();
  final table = Table(
    header: [
      'Symbol',
      'Markets',
      'Shipyards',
      'Charts',
    ],
    style: const TableStyle(compact: true),
  );

  for (final system in systemSymbols) {
    table.add([
      system,
      marketPrices.waypointSymbols.where((e) => e.system == system).length,
      shipyardPrices.waypointSymbols.where((e) => e.system == system).length,
      chartingCache.waypointSymbols.where((e) => e.system == system).length,
    ]);
  }

  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
