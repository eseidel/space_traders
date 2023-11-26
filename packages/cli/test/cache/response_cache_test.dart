import 'package:cli/api.dart';
import 'package:cli/cache/response_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

class _MockLogger extends Mock implements Logger {}

void main() {
  test('ResponseListCache', () async {
    final fs = MemoryFileSystem.test();
    final api = _MockApi();

    final responseCache = ResponseListCache(
      [1],
      refreshEntries: (_) async => [2],
      fs: fs,
      path: 'test.json',
      checkEvery: 3,
    );

    Future<Logger> ensureUpToDate() async {
      final logger = _MockLogger();
      await runWithLogger(logger, () async {
        await responseCache.ensureUpToDate(api);
      });
      return logger;
    }

    expect(responseCache.records.first, 1);
    await ensureUpToDate();
    expect(responseCache.records.first, 1);
    await ensureUpToDate();
    expect(responseCache.records.first, 1);
    final logger = await ensureUpToDate();
    expect(responseCache.records.first, 2);
    verify(
      () => logger.warn(
        'int list changed, updating cache.',
      ),
    ).called(1);

    final file = fs.file('test.json');
    expect(file.existsSync(), true);
    expect(file.readAsStringSync(), '[\n 2\n]');

    responseCache.replaceEntries([3]);
    expect(responseCache.records.first, 3);
  });
}
