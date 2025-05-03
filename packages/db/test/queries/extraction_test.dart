import 'package:db/src/queries/extraction.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ExtractionRecord round trip', () {
    final extraction = ExtractionRecord.fallbackValue();
    final map = extractionToColumnMap(extraction);
    final newExtraction = extractionFromColumnMap(map);
    expect(newExtraction, equals(extraction));
  });
}
