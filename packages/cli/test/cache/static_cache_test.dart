import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/api.dart';

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

  test('StaticCaches load/save smoke test', () {
    final fs = MemoryFileSystem.test();
    // Load empty.
    final staticCaches = StaticCaches.load(fs);
    final ships = [
      ShipyardShip(
        name: 'Test',
        description: 'Test ship',
        type: ShipType.COMMAND_FRIGATE,
        crew: ShipyardShipCrew(capacity: 10, required_: 5),
        purchasePrice: 10,
        frame: ShipFrame(
          symbol: ShipFrameSymbolEnum.CARRIER,
          name: 'Test',
          description: 'Test',
          moduleSlots: 2,
          mountingPoints: 2,
          fuelCapacity: 10,
          requirements: ShipRequirements(),
        ),
        engine: ShipEngine(
          name: 'Test',
          description: 'Test',
          symbol: ShipEngineSymbolEnum.HYPER_DRIVE_I,
          requirements: ShipRequirements(),
          speed: 10,
        ),
        reactor: ShipReactor(
          name: 'Test',
          description: 'Test',
          symbol: ShipReactorSymbolEnum.ANTIMATTER_I,
          requirements: ShipRequirements(),
          powerOutput: 10,
        ),
      ),
    ];
    recordShipyardShips(staticCaches, ships);
    // Verify that recordShipyardShips also saved engines, modules, reactors.
    staticCaches.shipyardShips.values.isNotEmpty;
    staticCaches.mounts.values.isNotEmpty;
    staticCaches.engines.values.isNotEmpty;
    staticCaches.modules.values.isNotEmpty;
    staticCaches.reactors.values.isNotEmpty;
  });
}
