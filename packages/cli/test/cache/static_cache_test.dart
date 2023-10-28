import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/api.dart';

void main() {
  test('StaticCaches load/save smoke test', () {
    final fs = MemoryFileSystem.test();
    // Load empty.
    final staticCaches = StaticCaches.load(fs);
    // Need two records with unique keys to test sorting.
    final ships = [
      ShipyardShip(
        supply: SupplyLevel.ABUNDANT,
        name: 'Test',
        description: 'Test ship',
        type: ShipType.COMMAND_FRIGATE,
        crew: ShipyardShipCrew(capacity: 10, required_: 5),
        purchasePrice: 10,
        frame: ShipFrame(
          symbol: ShipFrameSymbolEnum.FRIGATE,
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
        modules: [
          ShipModule(
            name: 'Test',
            description: 'Test',
            symbol: ShipModuleSymbolEnum.CREW_QUARTERS_I,
            requirements: ShipRequirements(),
            capacity: 10,
          ),
        ],
        mounts: [
          ShipMount(
            name: 'Test',
            description: 'Test',
            symbol: ShipMountSymbolEnum.GAS_SIPHON_I,
            requirements: ShipRequirements(),
          ),
        ],
      ),
      ShipyardShip(
        supply: SupplyLevel.ABUNDANT,
        name: 'Test2',
        description: 'Test ship 2',
        type: ShipType.EXPLORER,
        crew: ShipyardShipCrew(capacity: 10, required_: 5),
        purchasePrice: 10,
        frame: ShipFrame(
          symbol: ShipFrameSymbolEnum.EXPLORER,
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
          symbol: ShipEngineSymbolEnum.IMPULSE_DRIVE_I,
          requirements: ShipRequirements(),
          speed: 10,
        ),
        reactor: ShipReactor(
          name: 'Test',
          description: 'Test',
          symbol: ShipReactorSymbolEnum.CHEMICAL_I,
          requirements: ShipRequirements(),
          powerOutput: 10,
        ),
        modules: [
          ShipModule(
            name: 'Test',
            description: 'Test',
            symbol: ShipModuleSymbolEnum.FUEL_REFINERY_I,
            requirements: ShipRequirements(),
            capacity: 10,
          ),
        ],
        mounts: [
          ShipMount(
            name: 'Test',
            description: 'Test',
            symbol: ShipMountSymbolEnum.LASER_CANNON_I,
            requirements: ShipRequirements(),
          ),
        ],
      ),
    ];
    recordShipyardShips(staticCaches, ships);
    // Verify that recordShipyardShips also saved engines, modules, reactors.
    expect(staticCaches.shipyardShips.values.length, 2);
    expect(staticCaches.engines.values.length, 2);
    expect(staticCaches.modules.values.length, 2);
    expect(staticCaches.reactors.values.length, 2);
    expect(staticCaches.mounts.values.length, 2);

    // Save just to exercise the sorting code.
    staticCaches.engines.save();
    staticCaches.modules.save();
    staticCaches.reactors.save();
    staticCaches.shipyardShips.save();
    staticCaches.mounts.save();
  });
}
