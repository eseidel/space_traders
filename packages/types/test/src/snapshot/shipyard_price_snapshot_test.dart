import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('shipyard price snapshot', () {
    final snapshot = ShipyardPriceSnapshot([]);
    expect(snapshot.prices, isEmpty);
  });
}
