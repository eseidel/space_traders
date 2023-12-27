import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/jump_gate_cache.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockConstructionSnapshot extends Mock implements ConstructionSnapshot {}

void main() {
  test('SystemConnectivity.fromJumpGates', () async {
    final fs = MemoryFileSystem.test();
    final a = WaypointSymbol.fromString('X-A-A');
    final b = WaypointSymbol.fromString('X-B-B');
    final now = DateTime(2021);
    final constructionSnapshot = _MockConstructionSnapshot();
    when(() => constructionSnapshot.isUnderConstruction(a)).thenReturn(false);
    final jumpGateCache = JumpGateCache(
      [
        JumpGateRecord(waypointSymbol: a, connections: {b}, timestamp: now),
      ],
      fs: fs,
    );

    final unknownB = SystemConnectivity.fromJumpGates(
      jumpGateCache,
      constructionSnapshot,
    );
    // If construction status of 'b' is not known, then there is no path.
    expect(
      unknownB.existsJumpPathBetween(a.system, b.system),
      isFalse,
    );

    when(() => constructionSnapshot.isUnderConstruction(b)).thenReturn(false);
    final knownB = SystemConnectivity.fromJumpGates(
      jumpGateCache,
      constructionSnapshot,
    );
    expect(
      knownB.existsJumpPathBetween(a.system, b.system),
      isTrue,
    );

    expect(
      knownB.directlyConnectedSystemSymbols(a.system),
      {b.system},
    );
  });
}
