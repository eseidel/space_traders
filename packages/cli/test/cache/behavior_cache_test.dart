import 'package:cli/behavior/behavior.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('BehaviorCache roundtrip', () async {
    final fs = MemoryFileSystem.test();
    final stateByShipSymbol = {
      'S': BehaviorState('S', Behavior.buyShip),
    };
    final cache = BehaviorCache(stateByShipSymbol, fs: fs);
    await cache.save();
    final loaded = await BehaviorCache.load(fs);
    expect(loaded.getBehavior('S')!.behavior, stateByShipSymbol['S']!.behavior);
  });
}
