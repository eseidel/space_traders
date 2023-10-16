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
