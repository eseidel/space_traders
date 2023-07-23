import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

void main() {
  test('ClusterFinder single system', () {
    final systemsCache = _MockSystemsCache();
    final systemA = System(
      symbol: 'S-A',
      sectorSymbol: 'S',
      type: SystemType.BLACK_HOLE,
      x: 0,
      y: 0,
    );
    when(() => systemsCache.systems).thenReturn([systemA]);
    final systemSymbol = SystemSymbol.fromString('S-A');
    when(() => systemsCache.connectedSystems(systemSymbol)).thenReturn([]);
    final reachability = SystemConnectivity.fromSystemsCache(systemsCache);
    expect(reachability.connectedSystemCount(systemSymbol), equals(1));
  });

  test('ClusterFinder two systems', () {
    final systemsCache = _MockSystemsCache();
    final systemA = System(
      symbol: 'S-A',
      sectorSymbol: 'S',
      type: SystemType.BLACK_HOLE,
      x: 0,
      y: 0,
    );
    final systemB = System(
      symbol: 'S-B',
      sectorSymbol: 'S',
      type: SystemType.BLACK_HOLE,
      x: 0,
      y: 0,
    );
    when(() => systemsCache.systems).thenReturn([systemA, systemB]);
    when(() => systemsCache.connectedSystems(systemA.systemSymbol))
        .thenReturn([connectedSystemFromSystem(systemB, 0)]);
    when(() => systemsCache.connectedSystems(systemB.systemSymbol))
        .thenReturn([connectedSystemFromSystem(systemA, 0)]);
    final finder = SystemConnectivity.fromSystemsCache(systemsCache);
    expect(finder.connectedSystemCount(systemA.systemSymbol), equals(2));
  });
}
