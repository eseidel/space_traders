import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

void main() {
  test('ConstructionCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final waypointSymbol = WaypointSymbol.fromString('W-A-Y');
    final now = DateTime(2021);
    final record = ConstructionRecord(
      construction: null,
      waypointSymbol: waypointSymbol,
      timestamp: now,
    );
    ConstructionCache([record], fs: fs).save();
    final loaded = ConstructionCache.load(fs);
    expect(loaded.waypointCount, 1);
    expect(loaded.values.first.waypointSymbol, waypointSymbol);
    expect(loaded.waypointSymbolsUnderConstruction().length, 0);
    expect(loaded.isUnderConstruction(waypointSymbol), false);
    expect(loaded.recordForSymbol(waypointSymbol), record);
    expect(
      loaded.cacheAgeFor(waypointSymbol, getNow: () => now),
      Duration.zero,
    );
  });
}
