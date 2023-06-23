import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/advance.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class MockShip extends Mock implements Ship {}

class MockBehaviorContext extends Mock implements BehaviorContext {}

class MockLogger extends Mock implements Logger {}

void main() {
  test('BehaviorState JSON roundtrip', () async {
    final state = BehaviorState(Behavior.buyShip);
    final json = state.toJson();
    final newState = BehaviorState.fromJson(json);
    expect(newState.behavior, Behavior.buyShip);
    expect(newState.toJson(), json);
  });
}
