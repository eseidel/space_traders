import 'package:cli/api.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('WaypointTraitsCache', () {
    final fs = MemoryFileSystem();
    fs.file(WaypointTraitCache.defaultPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('[]');
    final waypointTraitCache = WaypointTraitCache.load(fs);
    final trait = WaypointTrait(
      symbol: WaypointTraitSymbol.VAST_RUINS,
      name: 'Vast Ruins',
      description: 'Vast Ruins',
    );
    waypointTraitCache.addAll([trait]);
    expect(waypointTraitCache[trait.symbol], trait);
  });
}
