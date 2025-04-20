import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('JumpGate', () {
    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
    final connections = {
      WaypointSymbol.fromString('S-A-A'),
      WaypointSymbol.fromString('S-B-C'),
    };
    final jumpGate = JumpGate(
      waypointSymbol: waypointSymbol,
      connections: connections,
    );
    expect(jumpGate.connectedSystemSymbols, {
      SystemSymbol.fromString('S-A'),
      SystemSymbol.fromString('S-B'),
    });

    final json = jumpGate.toJson();
    final fromJson = JumpGate.fromJson(json);
    expect(fromJson, jumpGate);
  });
}
