import 'package:db/src/queries/behavior.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('Behavior round trip', () {
    // Behavior state fields are all covered by BehaviorState round trip tests
    // at the types level.
    final behavior = BehaviorState(const ShipSymbol('S', 1), Behavior.idle);
    final map = behaviorStateToColumnMap(behavior);
    final newBehavior = behaviorStateFromColumnMap(map);
    expect(newBehavior.behavior, equals(behavior.behavior));
  });
}
