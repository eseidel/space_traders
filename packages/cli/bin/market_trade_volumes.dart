import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final marketPrices = await MarketPrices.load(db);
  final tradeVolumesBySymbol = <TradeSymbol, Set<int>>{};
  for (final price in marketPrices.prices) {
    final tradeSymbol = price.symbol;
    final tradeVolume = price.tradeVolume;
    tradeVolumesBySymbol.putIfAbsent(tradeSymbol, () => {}).add(tradeVolume);
  }
  final tradeSymbols = tradeVolumesBySymbol.keys.toList();
  for (final tradeSymbol in tradeSymbols) {
    final tradeVolumes = tradeVolumesBySymbol[tradeSymbol]!;
    if (tradeVolumes.length > 1) {
      logger.info('$tradeSymbol : ${tradeVolumes.join(', ')}');
    }
  }
  await db.close();
}
