import 'package:cli/ship_waiter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockShip extends Mock implements Ship {}

class _MockShipFrame extends Mock implements ShipFrame {}

void main() {
  test('ShipWaiter', () {
    final waiter = ShipWaiter();
    const aSymbol = ShipSymbol('a', 1);
    final aTime = DateTime.now();
    final ship = _MockShip();
    final shipFrame = _MockShipFrame();
    when(() => ship.symbol).thenReturn(aSymbol.symbol);
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.PROBE);
    waiter.scheduleShip(ship, aTime);
    final next = waiter.nextShip();
    expect(next.waitUntil, aTime);
  });

  test('ShipWaiter order', () {
    final waiter = ShipWaiter();
    const shortSymbol = ShipSymbol('a', 1);
    const longSymbol = ShipSymbol('a', 2);
    const nullTimeSymbol = ShipSymbol('a', 3);
    final short = _MockShip();
    final shipFrame = _MockShipFrame();
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.PROBE);
    when(() => short.symbol).thenReturn(shortSymbol.symbol);
    when(() => short.frame).thenReturn(shipFrame);
    final long = _MockShip();
    when(() => long.symbol).thenReturn(longSymbol.symbol);
    when(() => long.frame).thenReturn(shipFrame);
    final nullTime = _MockShip();
    when(() => nullTime.symbol).thenReturn(nullTimeSymbol.symbol);
    when(() => nullTime.frame).thenReturn(shipFrame);

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
