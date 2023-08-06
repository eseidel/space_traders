import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('setVerboseLogging', () {
    final logger = _MockLogger();
    // Mostly here for 100% coverage of logger.dart.
    runWithLogger(logger, setVerboseLogging);
    verify(() => logger.level = Level.verbose).called(1);
  });
}
