import 'package:cli/api.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('WaypointTraitsCache', () {
    final fs = MemoryFileSystem();
    fs.file(WaypointTraitCache.defaultPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('[]');
    final waypointTraitCache = WaypointTraitCache.load(fs);
    final trait = WaypointTrait(
      symbol: WaypointTraitSymbolEnum.VAST_RUINS,
      name: 'Vast Ruins',
      description: 'Vast Ruins',
    );
    waypointTraitCache.addAll([trait]);
    expect(waypointTraitCache[trait.symbol], trait);
  });
}
