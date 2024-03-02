import 'package:cli/cache/ship_snapshot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockShip extends Mock implements Ship {}

class _MockShipFrame extends Mock implements ShipFrame {}

void main() {
  test('frameCounts', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    final two = _MockShip();
    final twoFrame = _MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    final three = _MockShip();
    final threeFrame = _MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final shipCache = ShipSnapshot([one, two, three]);
    expect(
      shipCache.frameCounts,
      {ShipFrameSymbolEnum.MINER: 2, ShipFrameSymbolEnum.FIGHTER: 1},
    );

    expect(shipCache.countOfFrame(ShipFrameSymbolEnum.MINER), 2);
  });

  test('describeShips', () {
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
    expect(
      describeShips([one, two, three, four]),
      '2 Carrier, 1 Fighter, 1 Light Freighter',
    );
  });

  test('describeShips empty', () {
    expect(describeShips([]), '0 ships');
  });

  test('describeFleet one', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    expect(describeShips([one]), '1 Carrier');
  });
}
