import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/system_reachability.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

void main() {
  test('ClusterFinder single system', () {
    final systemsCache = _MockSystemsCache();
    when(() => systemsCache.connectedSystems('A')).thenReturn([]);
    final reachability = SystemReachability.fromSystemsCache(systemsCache);
    expect(reachability.connectedSystemCount('A'), equals(1));
  });

  test('ClusterFinder two systems', () {
    final systemsCache = _MockSystemsCache();
    when(() => systemsCache.connectedSystems('S-A')).thenReturn([
      ConnectedSystem(
        symbol: 'S-B',
        sectorSymbol: 'S',
        type: SystemType.BLACK_HOLE,
        distance: 0,
        x: 0,
        y: 0,
      )
    ]);
    when(() => systemsCache.connectedSystems('S-B')).thenReturn([
      ConnectedSystem(
        symbol: 'S-A',
        sectorSymbol: 'S',
        type: SystemType.BLACK_HOLE,
        distance: 0,
        x: 0,
        y: 0,
      )
    ]);
    final finder = SystemReachability.fromSystemsCache(systemsCache);
    expect(finder.connectedSystemCount('S-A'), equals(2));
  });
}
