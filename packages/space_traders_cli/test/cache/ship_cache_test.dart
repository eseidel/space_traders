import 'package:cli/api.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockShip extends Mock implements Ship {}

class _MockShipFrame extends Mock implements ShipFrame {}

void main() {
  test('frameCounts', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final two = _MockShip();
    final twoFrame = _MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final three = _MockShip();
    final threeFrame = _MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final shipCache = ShipCache([one, two, three]);
    expect(
      shipCache.frameCounts,
      {ShipFrameSymbolEnum.CARRIER: 2, ShipFrameSymbolEnum.FIGHTER: 1},
    );
  });

  test('describeFleet', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final two = _MockShip();
    final twoFrame = _MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final three = _MockShip();
    final threeFrame = _MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final four = _MockShip();
    final fourFrame = _MockShipFrame();
    when(() => four.frame).thenReturn(fourFrame);
    when(() => fourFrame.symbol)
        .thenReturn(ShipFrameSymbolEnum.LIGHT_FREIGHTER);
    final shipCache = ShipCache([one, two, three, four]);
    expect(
      describeFleet(shipCache),
      'Fleet: 2 Carrier, 1 Fighter, 1 Light Freighter',
    );
  });
}
