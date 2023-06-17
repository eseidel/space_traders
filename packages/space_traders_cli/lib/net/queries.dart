import 'package:space_traders_cli/api.dart';

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

/// Fetch user's [Agent] object.
Future<Agent> getMyAgent(Api api) async {
  final response = await api.agents.getMyAgent();
  return response!.data;
}

/// Fetch shipyard for a given waypoint, will throw if the waypoint does not
/// have a shipyard.
Future<Shipyard> getShipyard(Api api, Waypoint waypoint) async {
  final response = await api.systems.getShipyard(
    waypoint.systemSymbol,
    waypoint.symbol,
  );
  return response!.data;
}
