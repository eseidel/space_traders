import 'package:cli/api.dart';
import 'package:cli/cache/faction_cache.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

void main() {
  test('FactionCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final cache = FactionCache(
      [
        Faction(
          symbol: FactionSymbols.AEGIS,
          name: 'A',
          description: 'description',
          headquarters: 'headquarters',
          isRecruiting: true,
        )
      ],
      fs: fs,
    );
    expect(cache.factions.length, 1);
    await cache.save();
    final cache2 = FactionCache.loadFromCache(fs)!;
    expect(cache2.factions.length, 1);
  });
}
