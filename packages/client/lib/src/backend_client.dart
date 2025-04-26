import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:protocol/protocol.dart';

typedef Json = Map<String, dynamic>;

extension JsonDecode on http.Response {
  Map<String, dynamic> get json => jsonDecode(body) as Json;
}

class BackendClient {
  BackendClient({required this.hostedUri, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final Uri hostedUri;

  void close() => _httpClient.close();

  Uri _api(String path) => Uri.parse('$hostedUri/api/$path');

  Map<String, String> get _requestHeaders => <String, String>{
    HttpHeaders.contentTypeHeader: ContentType.json.value,
    HttpHeaders.acceptHeader: ContentType.json.value,
  };

  Future<Json> _get(Uri uri, {GetRequest? args}) async {
    final withArgs =
        args != null
            ? uri.replace(queryParameters: args.toQueryParameters())
            : uri;
    final response = await _httpClient.get(withArgs, headers: _requestHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
    return response.json;
  }

  Future<AccountingSummaryResponse> getAccountingSummary() async {
    final uri = _api('accounting/summary');
    final json = await _get(uri);
    return AccountingSummaryResponse.fromJson(json);
  }

  Future<AgentStatusResponse> getAgentStatus() async {
    final uri = _api('agent/status');
    final json = await _get(uri);
    return AgentStatusResponse.fromJson(json);
  }

  Future<DealsNearbyResponse> getNearbyDeals({
    required ShipType? shipType,
    required int? limit,
    required WaypointSymbol? start,
    required int? credits,
  }) async {
    final uri = _api('deals/nearby');
    final args = GetDealsNearbyRequest(
      shipType: shipType,
      limit: limit,
      start: start,
      credits: credits,
    );
    final json = await _get(uri, args: args);
    return DealsNearbyResponse.fromJson(json);
  }

  Future<PricedInventory> getFleetInventory() async {
    final uri = _api('fleet/inventory');
    final json = await _get(uri);
    return PricedInventory.fromJson(json);
  }

  Future<FleetShipsResponse> getFleetShips() async {
    final uri = _api('fleet/ships');
    final json = await _get(uri);
    return FleetShipsResponse.fromJson(json);
  }

  Future<GetTransactionsResponse> getRecentTransactions() async {
    final uri = _api('accounting/ledger/recent');
    final json = await _get(uri);
    return GetTransactionsResponse.fromJson(json);
  }

  Future<SystemStats> getSystemStats({SystemSymbol? startSystem}) async {
    final uri = _api('explore/system_stats');
    final args = GetSystemStatsRequest(startSystem: startSystem);
    final json = await _get(uri, args: args);
    return SystemStats.fromJson(json);
  }
}
