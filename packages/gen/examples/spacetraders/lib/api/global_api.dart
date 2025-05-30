import 'dart:async';
import 'dart:convert';

import 'package:spacetraders/api_client.dart';
import 'package:spacetraders/model/get_error_codes200_response.dart';
import 'package:spacetraders/model/get_status200_response.dart';

class GlobalApi {
  GlobalApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  Future<GetStatus200Response> getStatus() async {
    final response = await client.invokeApi(method: Method.get, path: '/');

    if (response.statusCode == 200) {
      return GetStatus200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load getStatus');
    }
  }

  Future<GetErrorCodes200Response> getErrorCodes() async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/error-codes',
    );

    if (response.statusCode == 200) {
      return GetErrorCodes200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load getErrorCodes');
    }
  }
}
