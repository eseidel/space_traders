import 'package:cli/api.dart';
import 'package:cli/ship_waiter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockShip extends Mock implements Ship {}

void main() {
  test('ShipWaiter', () {
    final waiter = ShipWaiter();
    final a = _MockShip();
    when(() => a.symbol).thenReturn('a');
    final aTime = DateTime.now();
    waiter.updateWaitUntil('a', aTime);
    expect(waiter.waitUntil('a'), aTime);
    waiter.updateForShips([a]);
    expect(waiter.waitUntil('a'), isNull);
  });
}
