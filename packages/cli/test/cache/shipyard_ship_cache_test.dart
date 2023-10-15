import 'package:cli/api.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('ShipyardShipCache', () {
    final fs = MemoryFileSystem();
    fs.file(ShipyardShipCache.defaultPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('[]');
    final shipyardShipCache = ShipyardShipCache.load(fs);
    final shipyardShip = ShipyardShip(
      type: ShipType.COMMAND_FRIGATE,
      name: 'name',
      description: 'description',
      purchasePrice: 10,
      crew: ShipyardShipCrew(
        required_: 0,
        capacity: 0,
      ),
      frame: ShipFrame(
        symbol: ShipFrameSymbolEnum.CARRIER,
        name: 'name',
        description: 'description',
        condition: 90,
        moduleSlots: 0,
        mountingPoints: 0,
        fuelCapacity: 0,
        requirements: ShipRequirements(crew: 0, power: 0, slots: 0),
      ),
      reactor: ShipReactor(
        symbol: ShipReactorSymbolEnum.FISSION_I,
        name: 'name',
        description: 'description',
        condition: 90,
        powerOutput: 100,
        requirements: ShipRequirements(crew: 0, power: 0, slots: 0),
      ),
      engine: ShipEngine(
        symbol: ShipEngineSymbolEnum.ION_DRIVE_I,
        name: 'name',
        description: 'description',
        condition: 90,
        speed: 100,
        requirements: ShipRequirements(crew: 0, power: 0, slots: 0),
      ),
    );
    shipyardShipCache.addAll([shipyardShip]);
    expect(shipyardShipCache.entries, hasLength(1));
  });
}
