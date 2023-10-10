import 'package:cli/cache/response_cache.dart';
import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('jsonListMatch smoke test', () {
    final logger = _MockLogger();
    final a = {'a': 1, 'b': 2};
    final b = {'a': 1, 'b': 2};
    final c = {'a': 1, 'b': 3};
    expect(jsonListMatch([a, b], [a, b], (t) => t), true);
    expect(jsonListMatch([a, b], [b, a], (t) => t), true);
    expect(
      runWithLogger(logger, () => jsonListMatch([a, b], [a, c], (t) => t)),
      false,
    );
    verify(
      () => logger.info(
        any(that: startsWith('Map<String, int> list differs at index 1')),
      ),
    ).called(1);

    reset(logger);
    expect(
      runWithLogger(logger, () => jsonListMatch([a, b], [a, b, b], (t) => t)),
      false,
    );
    verify(
      () => logger.info("Map<String, int> list lengths don't match: 2 != 3"),
    ).called(1);
  });
}
