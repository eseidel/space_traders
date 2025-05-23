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
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbol.MINER);
    final two = _MockShip();
    final twoFrame = _MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbol.MINER);
    final three = _MockShip();
    final threeFrame = _MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbol.FIGHTER);
    final shipCache = ShipSnapshot([one, two, three]);
    expect(shipCache.frameCounts, {
      ShipFrameSymbol.MINER: 2,
      ShipFrameSymbol.FIGHTER: 1,
    });

    expect(shipCache.countOfFrame(ShipFrameSymbol.MINER), 2);
  });

  test('describeShips', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbol.CARRIER);
    final two = _MockShip();
    final twoFrame = _MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbol.CARRIER);
    final three = _MockShip();
    final threeFrame = _MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbol.FIGHTER);
    final four = _MockShip();
    final fourFrame = _MockShipFrame();
    when(() => four.frame).thenReturn(fourFrame);
    when(() => fourFrame.symbol).thenReturn(ShipFrameSymbol.LIGHT_FREIGHTER);
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
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbol.CARRIER);
    expect(describeShips([one]), '1 Carrier');
  });
}
