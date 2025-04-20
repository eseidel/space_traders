import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:protocol/protocol.dart';

class BackendClient {
  BackendClient({http.Client? httpClient, Uri? hostedUri})
    : _httpClient = httpClient ?? http.Client(),
      hostedUri = hostedUri ?? Uri.http('server:8080');

  final http.Client _httpClient;
  final Uri hostedUri;

  Future<DealsNearbyResponse> getNearbyDeals() async {
    final uri = Uri.parse('$hostedUri/deals/nearby');
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load deals');
    }
    final json = response.body;
    final data = jsonDecode(json) as Map<String, dynamic>;
    return DealsNearbyResponse.fromJson(data);
  }
}
