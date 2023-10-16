import 'package:cli/ship_waiter.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ShipWaiter', () {
    final waiter = ShipWaiter();
    const aSymbol = ShipSymbol('a', 1);
    final aTime = DateTime.now();
    waiter.scheduleShip(aSymbol, aTime);
    final next = waiter.nextShip();
    expect(next.waitUntil, aTime);
  });

  test('ShipWaiter order', () {
    final waiter = ShipWaiter();
    const short = ShipSymbol('a', 1);
    const long = ShipSymbol('a', 2);
    const nullTime = ShipSymbol('a', 3);
    waiter
      ..scheduleShip(short, DateTime.now().add(const Duration(seconds: 1)))
      ..scheduleShip(
        long,
        DateTime.now().add(const Duration(seconds: 1000)),
      )
      ..scheduleShip(nullTime, null);
    expect(waiter.nextShip().shipSymbol, nullTimeSymbol);
    expect(waiter.nextShip().shipSymbol, shortSymbol);
    expect(waiter.nextShip().shipSymbol, longSymbol);
  });
}
