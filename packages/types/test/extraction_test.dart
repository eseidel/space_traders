import 'package:test/test.dart';
import 'package:types/extraction.dart';

void main() {
  test('ExtractionRecord round trip', () {
    final extraction = ExtractionRecord.fallbackValue();
    final json = extraction.toJson();
    final extraction2 = ExtractionRecord.fromJson(json);
    expect(extraction2, equals(extraction));
  });
}
