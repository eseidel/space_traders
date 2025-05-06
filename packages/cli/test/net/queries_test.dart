import 'package:cli/api.dart';
import 'package:cli/net/queries.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openapi/api.dart' as openapi;
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockApi extends Mock implements Api {}

class _MockSystemsApi extends Mock implements SystemsApi {}

void main() {
  test('fetchAllPages', () async {
    // set up
    const api = 'ignored';
    Future<(List<String>, Meta)> fetchPage(String api, int page) async {
      if (page == 1) {
        return (['a', 'b'], Meta(total: 3, limit: 2));
      } else if (page == 2) {
        return (['c'], Meta(total: 3, page: 2, limit: 2));
      } else {
        throw Exception('bad page');
      }
    }

    final list = await fetchAllPages(api, fetchPage).toList();
    expect(list, ['a', 'b', 'c']);
  });

  test('allSystems', () async {
    final api = _MockApi();
    final systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);

    // 0 -> A, 25 -> Z, 26 -> AA, 27 -> AB, etc.
    String toLetters(int i) {
      final letters = <String>[];
      var remaining = i;
      // Make sure we return at least one letter.
      do {
        letters.add(String.fromCharCode(65 + (remaining % 26)));
        remaining ~/= 26;
      } while (remaining > 0);
      return letters.reversed.join();
    }

    final expectedSystems = List<openapi.System>.generate(
      100,
      (i) =>
          System.test(SystemSymbol.fromString('A-${toLetters(i)}')).toOpenApi(),
    );
    when(
      () => systemsApi.getSystems(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      // page is 1-indexed.
      final page = invocation.namedArguments[#page] as int;
      final limit = invocation.namedArguments[#limit] as int;
      final offset = (page - 1) * limit;
      return GetSystems200Response(
        data: expectedSystems.sublist(offset, offset + limit),
        meta: Meta(total: 100),
      );
    });
    final systems = await allSystems(api).toList();
    expect(systems.length, 100);
    // Values returned are our System type, not the openapi type.
    expect(systems.first.symbol.system, expectedSystems.first.symbol);
    expect(systems.last.symbol.system, expectedSystems.last.symbol);
  });
}
