import 'package:file/memory.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:test/test.dart';

void main() {
  test('BehaviorState JSON roundtrip', () async {
    final state = BehaviorState('S', Behavior.buyShip);
    final json = state.toJson();
    final newState = BehaviorState.fromJson(json);
    expect(newState.shipSymbol, 'S');
    expect(newState.behavior, Behavior.buyShip);
    expect(newState.toJson(), json);
  });

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
