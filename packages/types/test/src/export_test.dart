import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('TradeExport round trip', () {
    const export = TradeExport(
      export: TradeSymbol.ADVANCED_CIRCUITRY,
      imports: [TradeSymbol.COPPER, TradeSymbol.ELECTRONICS],
    );
    final json = export.toJson();
    final export2 = TradeExport.fromJson(json);
    expect(export2, equals(export));
    expect(export2.hashCode, equals(export.hashCode));
  });
}
