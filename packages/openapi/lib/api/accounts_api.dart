import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openapi/api_client.dart';
import 'package:openapi/api_exception.dart';
import 'package:openapi/model/get_my_account200_response.dart';
import 'package:openapi/model/register201_response.dart';
import 'package:openapi/model/register_request.dart';

class AccountsApi {
  AccountsApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  Future<GetMyAccount200Response> getMyAccount() async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/my/account',
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return GetMyAccount200Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $getMyAccount',
    );
  }

  Future<Register201Response> register(RegisterRequest registerRequest) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/register',
      bodyJson: registerRequest.toJson(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Register201Response.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $register',
    );
  }
}
