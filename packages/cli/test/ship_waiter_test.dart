import 'package:cli/logic/ship_waiter.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ShipWaiter', () {
    final waiter = ShipWaiter();
    const aSymbol = ShipSymbol('a', 1);
    final aTime = DateTime(2021);
    waiter.scheduleShip(aSymbol, aTime);
    final next = waiter.nextShip();
    expect(next.waitUntil, aTime);
  });

  test('ShipWaiter order', () {
    final waiter = ShipWaiter();
    const short = ShipSymbol('a', 1);
    const long = ShipSymbol('a', 2);
    const nullTime = ShipSymbol('a', 3);
    final now = DateTime(2021);
    waiter
      ..scheduleShip(short, now.add(const Duration(seconds: 1)))
      ..scheduleShip(long, now.add(const Duration(seconds: 1000)))
      ..scheduleShip(nullTime, null);
    expect(waiter.nextShip().shipSymbol, nullTime);
    expect(waiter.nextShip().shipSymbol, short);
    expect(waiter.nextShip().shipSymbol, long);
  });
}
