import 'package:cli/compare.dart';
import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('jsonMatches', () {
    final logger = _MockLogger();
    runWithLogger(logger, () {
      expect(jsonMatches([1], [2]), isFalse);
      expect(jsonMatches([1], [1]), isTrue);
      expect(jsonMatches(1, 1), isTrue);
    });
  });
}
