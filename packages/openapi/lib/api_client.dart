import 'dart:io';

import 'package:http/http.dart';
import 'package:openapi/api_exception.dart';

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
    Map<String, String> queryParameters = const {},
    // Body is nullable to allow for post requests which have an optional body
    // to not have to generate two separate calls depending on whether the
    // body is present or not.
    Map<String, dynamic>? body,
  }) async {
    final uri = resolvePath(path);
    if (method == Method.get && body != null) {
      throw ArgumentError('Body is not allowed for GET requests');
    }

    try {
      switch (method) {
        case Method.get:
          final withParams = uri.replace(
            queryParameters: {...baseUri.queryParameters, ...queryParameters},
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
