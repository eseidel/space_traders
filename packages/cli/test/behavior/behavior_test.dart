import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:test/test.dart';

void main() {
  test('BehaviorState JSON roundtrip', () async {
    const shipSymbol = ShipSymbol('S', 1);
    final state = BehaviorState(shipSymbol, Behavior.buyShip);
    final json = state.toJson();
    final newState = BehaviorState.fromJson(json);
    expect(newState.shipSymbol, shipSymbol);
    expect(newState.behavior, Behavior.buyShip);
    expect(newState.toJson(), json);
  });
}
