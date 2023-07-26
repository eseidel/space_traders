import 'package:cli/api.dart';
import 'package:cli/ship_waiter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockShip extends Mock implements Ship {}

void main() {
  test('ShipWaiter', () {
    final waiter = ShipWaiter();
    final a = _MockShip();
    const aSymbol = ShipSymbol('a', 1);
    when(() => a.symbol).thenReturn(aSymbol.symbol);
    final aTime = DateTime.now();
    waiter.updateWaitUntil(aSymbol, aTime);
    expect(waiter.waitUntil(aSymbol), aTime);
    expect(waiter.earliestWaitUntil(), aTime);
    waiter.updateForShips([a]);
    expect(waiter.waitUntil(aSymbol), isNull);
  });
}
