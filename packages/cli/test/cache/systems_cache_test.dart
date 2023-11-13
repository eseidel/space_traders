import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('SystemCache load http failure', () async {
    final fs = MemoryFileSystem();
    Future<http.Response> mockGet(Uri uri) async {
      return http.Response('Not Found', 404);
    }

    final logger = _MockLogger();
    try {
      await runWithLogger(
        logger,
        () => SystemsCache.loadOrFetch(fs, httpGet: mockGet),
      );
      fail('exception not thrown');
    } on ApiException catch (e) {
      expect(e.code, 404);
    }
  });
}
