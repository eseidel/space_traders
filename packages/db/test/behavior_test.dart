import 'package:db/behavior.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('Behavior round trip', () {
    // TODO(eseidel): test more BehaviorState fields.
    final behavior = BehaviorState(const ShipSymbol('S', 1), Behavior.idle);
    final map = behaviorStateToColumnMap(behavior);
    final newBehavior = behaviorStateFromColumnMap(map);
    expect(newBehavior.behavior, equals(behavior.behavior));
  });
}
