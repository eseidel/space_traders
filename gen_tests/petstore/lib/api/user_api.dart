import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:petstore/api_client.dart';
import 'package:petstore/api_exception.dart';
import 'package:petstore/model/user.dart';

class UserApi {
  UserApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  Future<User> createUser({User? user}) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/user',
      body: user?.toJson(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $createUser',
    );
  }

  Future<User> createUsersWithListInput({List<User>? list}) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/user/createWithList',
      body: list?.map((e) => e.toJson()).toList(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $createUsersWithListInput',
    );
  }

  Future<String> loginUser({String? username, String? password}) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/user/login',
      queryParameters: {
        'username': username.toString(),
        'password': password.toString(),
      },
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return jsonDecode(response.body) as String;
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $loginUser',
    );
  }

  Future<void> logoutUser() async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/user/logout',
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return;
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $logoutUser',
    );
  }

  Future<User> getUserByName(String username) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/user/{username}'.replaceAll('{username}', username),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $getUserByName',
    );
  }

  Future<void> updateUser(String username, {User? user}) async {
    final response = await client.invokeApi(
      method: Method.put,
      path: '/user/{username}'.replaceAll('{username}', username),
      body: user?.toJson(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return;
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $updateUser',
    );
  }

  Future<void> deleteUser(String username) async {
    final response = await client.invokeApi(
      method: Method.delete,
      path: '/user/{username}'.replaceAll('{username}', username),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return;
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $deleteUser',
    );
  }
}
