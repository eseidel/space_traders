import 'package:test/test.dart';
import 'package:types/src/extraction.dart';

void main() {
  test('ExtractionRecord round trip', () {
    final extraction = ExtractionRecord.fallbackValue();
    final json = extraction.toJson();
    final extraction2 = ExtractionRecord.fromJson(json);
    expect(extraction2, equals(extraction));
    expect(extraction2.hashCode, equals(extraction.hashCode));
  });
}
