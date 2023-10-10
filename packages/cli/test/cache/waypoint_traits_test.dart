import 'package:cli/api.dart';
import 'package:cli/cache/waypoint_traits.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('WaypointTraitsCache', () {
    final fs = MemoryFileSystem();
    fs.file('data/waypoint_traits.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{}');
    final waypointTraitCache = WaypointTraitCache.load(fs);
    final trait = WaypointTrait(
      symbol: WaypointTraitSymbolEnum.VAST_RUINS,
      name: 'Vast Ruins',
      description: 'Vast Ruins',
    );
    waypointTraitCache.addTraits([trait]);
    expect(waypointTraitCache.traitFromSymbol(trait.symbol), trait);
  });
}
