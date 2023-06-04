import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';

// Need to make these generic for all paginated apis.

/// Fetches all pages from the given fetchPage function.
Stream<T> fetchAllPages<T, A>(
  A api,
  Future<(List<T>, Meta)> Function(A api, int page) fetchPage,
) async* {
  var page = 1;
  var count = 0;
  var remaining = 0;
  do {
    final (values, meta) = await fetchPage(api, page);
    count += values.length;
    remaining = meta.total - count;
    for (final value in values) {
      yield value;
    }
    page++;
  } while (remaining > 0);
}

/// Fetches all of the user's ships.  Handles pagination from the server.
Stream<Ship> allMyShips(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.fleet.getMyShips(page: page);
    return (response!.data, response.meta);
  });
}

/// Fetches all of the user's contracts.  Handles pagination from the server.
Stream<Contract> allMyContracts(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.contracts.getContracts(page: page);
    return (response!.data, response.meta);
  });
}

/// Fetches all factions.  Handles pagination from the server.
Stream<Faction> getAllFactions(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.factions.getFactions(page: page);
    return (response!.data, response.meta);
  });
}
