import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('BehaviorCache roundtrip', () async {
    final fs = MemoryFileSystem.test();
    const shipSymbol = ShipSymbol('S', 1);
    final stateByShipSymbol = {
      shipSymbol: BehaviorState(shipSymbol, Behavior.buyShip),
    };
    BehaviorCache(stateByShipSymbol, fs: fs).save();
    final loaded = BehaviorCache.load(fs);
    expect(
      loaded.getBehavior(shipSymbol)!.behavior,
      stateByShipSymbol[shipSymbol]!.behavior,
    );
  });
}
