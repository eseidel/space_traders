import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, List<String> args) async {
  final marketPrices = MarketPrices.load(fs);
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
}
