import 'package:test/test.dart';
import "package:types/types.dart";

void main() {
  test('GamePhase json round trip', () {
    final phase = GamePhase.bootstrap;
    final json = phase.toJson();
    final phase2 = GamePhase.fromJson(json);
    expect(phase, phase2);

    // Verify that our old JSON format still works, remove on next reset.
    final phase3 = GamePhase.fromJson(phase.toString());
    expect(phase, phase3);
  });
}
