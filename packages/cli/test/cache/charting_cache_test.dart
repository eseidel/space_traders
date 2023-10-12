import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_traits.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

void main() {
  test('ChartingCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final a = WaypointSymbol.fromString('S-S-A');
    final values = ChartedValues(
      waypointSymbol: a,
      chart: Chart(
        waypointSymbol: a.waypoint,
        submittedBy: 'ESEIDEL',
        submittedOn: DateTime(2021),
      ),
      faction: WaypointFaction(
        symbol: FactionSymbols.AEGIS,
      ),
      traitSymbols: const [
        WaypointTraitSymbolEnum.ASH_CLOUDS,
      ],
    );
    final waypointTraits = _MockWaypointTraitCache();
    final valuesBySymbol = {values.waypointSymbol: values};
    ChartingCache(valuesBySymbol, waypointTraits, fs: fs).save();
    final loaded = ChartingCache.load(fs);
    expect(loaded.waypointCount, 1);
    expect(loaded.values.first.waypointSymbol, a);
    expect(loaded.values.first.chart.submittedBy, 'ESEIDEL');
    expect(loaded.values.first.faction?.symbol, FactionSymbols.AEGIS);
    expect(loaded.values.first.traitSymbols, hasLength(1));
    expect(
      loaded.values.first.traitSymbols.first,
      WaypointTraitSymbolEnum.ASH_CLOUDS,
    );
  });

  test('ChartingCache', () async {
    final fs = MemoryFileSystem.test();
    final waypointTraits = _MockWaypointTraitCache();
    final waypointSymbol = WaypointSymbol.fromString('A-A-A');
    final unchartedSymbol = WaypointSymbol.fromString('B-B-B');
    final chartedWaypoint = Waypoint(
      symbol: waypointSymbol.waypoint,
      type: WaypointType.ASTEROID_FIELD,
      systemSymbol: waypointSymbol.system,
      x: 0,
      y: 0,
      // Chart is required for the cache to work.
      chart: Chart(
        waypointSymbol: waypointSymbol.waypoint,
        submittedBy: 'ESEIDEL',
        submittedOn: DateTime(2021),
      ),
    );
    final unchartedWaypoint = Waypoint(
      symbol: waypointSymbol.waypoint,
      type: WaypointType.ASTEROID_FIELD,
      systemSymbol: unchartedSymbol.system,
      x: 0,
      y: 0,
      // No chart, so this won't be cached.
    );
    final chartingCache = ChartingCache({}, waypointTraits, fs: fs)
      ..addWaypoints([
        chartedWaypoint,
        unchartedWaypoint,
      ]);
    expect(chartingCache.waypointCount, 1);
    expect(chartingCache.valuesForSymbol(waypointSymbol), isNotNull);
    expect(chartingCache.valuesForSymbol(unchartedSymbol), isNull);

    final systemsCache = _MockSystemsCache();
    when(() => systemsCache.waypointFromSymbol(waypointSymbol))
        .thenReturn(chartedWaypoint.toSystemWaypoint());
    final waypoint2 =
        chartingCache.waypointFromSymbol(systemsCache, waypointSymbol);
    expect(waypoint2?.chart, isNotNull);

    final uncharted2 =
        chartingCache.waypointFromSymbol(systemsCache, unchartedSymbol);
    expect(uncharted2, isNull);
  });
}
