import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
import 'package:test/test.dart';

class MockShip extends Mock implements Ship {}

class MockShipFrame extends Mock implements ShipFrame {}

void main() {
  test('frameCounts', () {
    final one = MockShip();
    final oneFrame = MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final two = MockShip();
    final twoFrame = MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final three = MockShip();
    final threeFrame = MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final shipCache = ShipCache([one, two, three]);
    expect(
      shipCache.frameCounts,
      {ShipFrameSymbolEnum.CARRIER: 2, ShipFrameSymbolEnum.FIGHTER: 1},
    );
  });

  test('describeFleet', () {
    final one = MockShip();
    final oneFrame = MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final two = MockShip();
    final twoFrame = MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final three = MockShip();
    final threeFrame = MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final four = MockShip();
    final fourFrame = MockShipFrame();
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
