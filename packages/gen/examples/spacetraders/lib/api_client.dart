import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:spacetraders/api_exception.dart';

enum Method { get, post, patch }

class ApiClient {
  ApiClient({Uri? baseUri, Client? client, this.defaultHeaders = const {}})
    : baseUri = baseUri ?? Uri.parse('https://api.spacetraders.io/v2'),
      client = client ?? Client();

  final Uri baseUri;
  final Client client;
  final Map<String, String> defaultHeaders;

  Map<String, String> get headers => <String, String>{
    ...defaultHeaders,
    'Content-Type': 'application/json',
  };

  Uri resolvePath(String path) => baseUri.resolve(path).resolve(path);

  Future<Response> invokeApi({
    required Method method,
    required String path,
    Map<String, dynamic> parameters = const {},
  }) async {
    final uri = resolvePath(path);
    final body = method != Method.get ? jsonEncode(parameters) : null;

    try {
      switch (method) {
        case Method.get:
          final withParams = uri.replace(
            queryParameters: {...baseUri.queryParameters, ...parameters},
          );
          return client.get(withParams, headers: headers);
        case Method.post:
          return client.post(uri, headers: headers, body: body);
        case Method.patch:
          return client.patch(uri, headers: headers, body: body);
      }
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }
  }
}
