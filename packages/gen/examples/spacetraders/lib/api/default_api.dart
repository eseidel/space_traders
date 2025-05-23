import 'dart:async';

import 'package:spacetraders/api_client.dart';

class DefaultApi {
  DefaultApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  Future<void> health() async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/health',
      parameters: {},
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to load health');
    }
  }

  Future<void> metrics() async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/metrics',
      parameters: {},
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to load metrics');
    }
  }
}
