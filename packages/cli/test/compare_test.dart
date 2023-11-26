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

  test('jsonMatches with list', () {
    final logger = _MockLogger();
    final a = {'a': 1, 'b': 2};
    final b = {'a': 1, 'b': 2};
    final c = {'a': 1, 'b': 3};
    expect(jsonMatches([a, b], [a, b]), true);
    expect(jsonMatches([a, b], [b, a]), true);
    expect(
      runWithLogger(logger, () => jsonMatches([a, b], [a, c])),
      false,
    );
    verify(
      () => logger.info(
        'List<Map<String, int>> differs from expected: '
        '@ Changed at path "[1, b]":\n'
        '- 2\n'
        '+ 3',
      ),
    ).called(1);

    reset(logger);
    expect(
      runWithLogger(logger, () => jsonMatches([a, b], [a, b, b])),
      false,
    );
    verify(
      () => logger.info(
        'List<Map<String, int>> differs from expected: '
        '@ Added to right at path "[2]":\n'
        '+ {"a":1,"b":2}',
      ),
    ).called(1);
  });
}
