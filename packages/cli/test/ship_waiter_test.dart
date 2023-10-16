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

  test('ShipWaiter priority', () {
    final waiter = ShipWaiter();
    const probeSymbol = ShipSymbol('a', 1);
    const otherSymbol = ShipSymbol('a', 2);
    final probe = _MockShip();
    final probeFrame = _MockShipFrame();
    when(() => probeFrame.symbol).thenReturn(ShipFrameSymbolEnum.PROBE);
    when(() => probe.symbol).thenReturn(probeSymbol.symbol);
    when(() => probe.frame).thenReturn(probeFrame);

    final other = _MockShip();
    final otherFrame = _MockShipFrame();
    when(() => otherFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    when(() => other.symbol).thenReturn(otherSymbol.symbol);
    when(() => other.frame).thenReturn(otherFrame);

    final now = DateTime.timestamp();
    final longAgo = now.subtract(const Duration(days: 1));
    final recent = now.subtract(const Duration(hours: 1));

    waiter
      ..scheduleShip(probe, longAgo)
      ..scheduleShip(other, recent);
    expect(waiter.nextShip().shipSymbol, otherSymbol);
    expect(waiter.nextShip().shipSymbol, probeSymbol);

    // If we schedule again but make the probe not a probe, it should be first.
    when(() => probe.frame).thenReturn(otherFrame);
    waiter
      ..scheduleShip(probe, longAgo)
      ..scheduleShip(other, recent);
    expect(waiter.nextShip().shipSymbol, probeSymbol);
    expect(waiter.nextShip().shipSymbol, otherSymbol);
  });
}
