import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

void main() {
  test('ChartingCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final a = WaypointSymbol.fromString('S-S-A');
    final b = WaypointSymbol.fromString('S-S-B');
    final values = ChartedValues(
      chart: Chart(
        waypointSymbol: a.waypoint,
        submittedBy: 'ESEIDEL',
        submittedOn: DateTime(2021),
      ),
      faction: WaypointFaction(
        symbol: FactionSymbol.AEGIS,
      ),
      traitSymbols: const {
        WaypointTraitSymbol.ASH_CLOUDS,
      },
    );
    final waypointTraits = _MockWaypointTraitCache();
    final valuesBySymbol = {
      a: ChartingRecord(
        waypointSymbol: a,
        values: values,
        timestamp: DateTime(2021),
      ),
      b: ChartingRecord(
        waypointSymbol: b,
        values: null,
        timestamp: DateTime(2021),
      ),
    };
    ChartingCache(valuesBySymbol, waypointTraits, fs: fs).save();
    final loaded = ChartingCache.load(fs, waypointTraits);
    expect(loaded.records, hasLength(2));
    expect(loaded.records.first.waypointSymbol, a);
    expect(loaded.waypointCount, 2);
    expect(loaded.values.length, 1);
    expect(loaded.values.first.chart.submittedBy, 'ESEIDEL');
    expect(loaded.values.first.faction?.symbol, FactionSymbol.AEGIS);
    expect(loaded.values.first.traitSymbols, hasLength(1));
    expect(
      loaded.values.first.traitSymbols.first,
      WaypointTraitSymbol.ASH_CLOUDS,
    );
    expect(loaded.records.last.waypointSymbol, b);
    expect(loaded.records.last.values, isNull);
  });

  test('ChartingCache', () async {
    final fs = MemoryFileSystem.test();
    final waypointTraits = _MockWaypointTraitCache();
    final waypointSymbol = WaypointSymbol.fromString('A-A-A');
    final unchartedSymbol = WaypointSymbol.fromString('B-B-B');
    final waypointTrait = WaypointTrait(
      symbol: WaypointTraitSymbol.ASH_CLOUDS,
      name: 'Ash Clouds',
      description: 'Ash Clouds',
    );
    when(() => waypointTraits[WaypointTraitSymbol.ASH_CLOUDS])
        .thenReturn(waypointTrait);
    final chartedWaypoint = Waypoint(
      symbol: waypointSymbol.waypoint,
      type: WaypointType.ASTEROID_FIELD,
      systemSymbol: waypointSymbol.system,
      x: 0,
      y: 0,
      traits: [waypointTrait],
      chart: Chart(
        waypointSymbol: waypointSymbol.waypoint,
        submittedBy: 'ESEIDEL',
        submittedOn: DateTime(2021),
      ),
      isUnderConstruction: false,
    );
    final unchartedWaypoint = Waypoint(
      symbol: unchartedSymbol.waypoint,
      type: WaypointType.ASTEROID_FIELD,
      systemSymbol: unchartedSymbol.system,
      x: 0,
      y: 0,
      isUnderConstruction: false,
      // No chart, but will still be cached.
    );
    final chartingCache = ChartingCache({}, waypointTraits, fs: fs)
      ..addWaypoints([
        chartedWaypoint,
        unchartedWaypoint,
      ]);
    expect(chartingCache.waypointCount, 2);
    expect(chartingCache.getRecord(waypointSymbol), isNotNull);
    expect(chartingCache.getRecord(unchartedSymbol), isNotNull);
    expect(chartingCache[waypointSymbol], isNotNull);
    expect(chartingCache[unchartedSymbol], isNull);
  });
}
