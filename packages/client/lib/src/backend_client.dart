import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:protocol/protocol.dart';
import 'package:types/types.dart';

class BackendClient {
  BackendClient({required this.hostedUri, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final Uri hostedUri;

  void close() {
    _httpClient.close();
  }

  Future<DealsNearbyResponse> getNearbyDeals({
    required ShipType? shipType,
    required int? limit,
    required WaypointSymbol? start,
    required int? credits,
  }) async {
    final request = GetDealsNearbyRequest(
      shipType: shipType,
      limit: limit,
      start: start,
      credits: credits,
    );
    final uri = Uri.parse(
      '$hostedUri/api/deals/nearby',
    ).replace(queryParameters: request.toQueryParameters());
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final response = await _httpClient.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load deals');
    }
    final json = response.body;
    final data = jsonDecode(json) as Map<String, dynamic>;
    return DealsNearbyResponse.fromJson(data);
  }

  Future<GetFleetInventoryResponse> getFleetInventory() async {
    final uri = Uri.parse('$hostedUri/api/fleet/inventory');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final response = await _httpClient.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load inventory value');
    }
    final json = response.body;
    final data = jsonDecode(json) as Map<String, dynamic>;
    return GetFleetInventoryResponse.fromJson(data);
  }
}
