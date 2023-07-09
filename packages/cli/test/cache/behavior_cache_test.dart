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
    BehaviorCache(stateByShipSymbol, fs: fs).save();
    final loaded = BehaviorCache.load(fs);
    expect(loaded.getBehavior('S')!.behavior, stateByShipSymbol['S']!.behavior);
  });
}
