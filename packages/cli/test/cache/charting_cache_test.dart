import 'package:cli/api.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/waypoint_traits.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

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
      traitSymbols: const [
        WaypointTraitSymbolEnum.ASH_CLOUDS,
      ],
      orbitals: [
        WaypointOrbital(
          symbol: 'F',
        ),
      ],
    );
    final waypointTraits = _MockWaypointTraitCache();
    final valuesBySymbol = {values.waypointSymbol: values};
    ChartingCache(valuesBySymbol, waypointTraits, fs: fs).save();
    final loaded = ChartingCache.load(fs);
    expect(loaded.waypointCount, 1);
    expect(loaded.values.first.waypointSymbol, 'A');
    expect(loaded.values.first.chart.submittedBy, 'ESEIDEL');
    expect(loaded.values.first.faction?.symbol, FactionSymbols.AEGIS);
    expect(loaded.values.first.traitSymbols, hasLength(1));
    expect(
      loaded.values.first.traitSymbols.first,
      WaypointTraitSymbolEnum.ASH_CLOUDS,
    );
    expect(loaded.values.first.orbitals, hasLength(1));
  });
}
