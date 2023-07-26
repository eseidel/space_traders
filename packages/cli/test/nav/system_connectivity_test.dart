import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

void main() {
  test('SystemConnectivity single system', () {
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

  test('SystemConnectivity two systems', () {
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
    final systemConnectivity =
        SystemConnectivity.fromSystemsCache(systemsCache);
    expect(
      systemConnectivity.connectedSystemCount(systemA.systemSymbol),
      equals(2),
    );

    final clusterId =
        systemConnectivity.clusterIdForSystem(systemA.systemSymbol);
    final systems =
        systemConnectivity.systemSymbolsByClusterId(clusterId).toList();
    expect(systems, [systemA.systemSymbol, systemB.systemSymbol]);
  });
}
