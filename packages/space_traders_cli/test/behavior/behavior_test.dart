import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:test/test.dart';

void main() {
  test('BehaviorState JSON roundtrip', () async {
    final state = BehaviorState('S', Behavior.buyShip);
    final json = state.toJson();
    final newState = BehaviorState.fromJson(json);
    expect(newState.shipSymbol, 'S');
    expect(newState.behavior, Behavior.buyShip);
    expect(newState.toJson(), json);
  });
}
