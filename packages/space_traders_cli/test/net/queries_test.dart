import 'package:cli/api.dart';
import 'package:cli/net/queries.dart';
import 'package:test/test.dart';

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
}
