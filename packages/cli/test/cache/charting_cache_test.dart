import 'package:cli/api.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('ChartingCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final values = ChartedValues(
      //       required this.waypointSymbol,
      // required this.chart,
      // required this.faction,
      // required this.traits,
      // required this.orbitals,
      waypointSymbol: 'A',
      chart: Chart(
        waypointSymbol: 'A',
        submittedBy: 'ESEIDEL',
        submittedOn: DateTime(2021),
      ),
      faction: WaypointFaction(
        symbol: FactionSymbols.AEGIS,
      ),
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbolEnum.ASH_CLOUDS,
          name: 'Ash Clouds',
          description: 'Ash Clouds',
        ),
      ],
      orbitals: [
        WaypointOrbital(
          symbol: 'F',
        ),
      ],
    );
    final valuesBySymbol = {values.waypointSymbol: values};
    ChartingCache(valuesBySymbol, fs: fs).save();
    final loaded = ChartingCache.load(fs);
    expect(loaded.waypointCount, 1);
    expect(loaded.values.first.waypointSymbol, 'A');
    expect(loaded.values.first.chart.submittedBy, 'ESEIDEL');
    expect(loaded.values.first.faction.symbol, FactionSymbols.AEGIS);
    expect(loaded.values.first.traits, hasLength(1));
    expect(
      loaded.values.first.traits.first.symbol,
      WaypointTraitSymbolEnum.ASH_CLOUDS,
    );
    expect(loaded.values.first.orbitals, hasLength(1));
  });
}
