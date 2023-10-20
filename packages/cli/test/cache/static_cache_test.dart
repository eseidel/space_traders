import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('StaticCaches load/save smoke test', () {
    final fs = MemoryFileSystem.test();
    // Load empty.
    final staticCaches = StaticCaches.load(fs);
    // Save just to exercise the sorting code.
    staticCaches.engines.save();
    staticCaches.modules.save();
    staticCaches.reactors.save();
    staticCaches.shipyardShips.save();
    staticCaches.mounts.save();
  });
}
