import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:petstore/api_client.dart';
import 'package:petstore/api_exception.dart';
import 'package:petstore/model/order.dart';

class StoreApi {
  StoreApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  Future<Map<String, int>> getInventory() async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/store/inventory',
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return {
        for (final entry
            in (jsonDecode(response.body) as Map<String, dynamic>).entries)
          entry.key: (entry.value as int),
      };
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $getInventory',
    );
  }

  Future<Order> placeOrder({Order? order}) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/store/order',
      body: order?.toJson(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $placeOrder',
    );
  }

  Future<Order> getOrderById(int orderId) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/store/order/{orderId}'.replaceAll('{orderId}', '$orderId'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $getOrderById',
    );
  }

  Future<void> deleteOrder(int orderId) async {
    final response = await client.invokeApi(
      method: Method.delete,
      path: '/store/order/{orderId}'.replaceAll('{orderId}', '$orderId'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return;
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $deleteOrder',
    );
  }
}
