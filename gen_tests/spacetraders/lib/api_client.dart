import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:spacetraders/api_exception.dart';

enum Method {
  delete,
  get,
  patch,
  post,
  put;

  bool get supportsBody => this != get && this != delete;
}

class ApiClient {
  ApiClient({Uri? baseUri, Client? client, this.defaultHeaders = const {}})
    : baseUri = baseUri ?? Uri.parse('https://api.spacetraders.io/v2'),
      client = client ?? Client();

  final Uri baseUri;
  final Client client;
  final Map<String, String> defaultHeaders;

  // baseUri can contain a path, so we need to resolve the passed path relative
  // to it.  The passed path will always be absolute (leading slash) but should
  // be interpreted as relative to the baseUri.
  Uri resolvePath(String path) => Uri.parse('$baseUri$path');

  Future<Response> invokeApi({
    required Method method,
    required String path,
    Map<String, String> queryParameters = const {},
    // Body is nullable to allow for post requests which have an optional body
    // to not have to generate two separate calls depending on whether the
    // body is present or not.
    dynamic body,
    Map<String, String> headerParameters = const {},
  }) async {
    final uri = resolvePath(path);
    if (!method.supportsBody && body != null) {
      throw ArgumentError('Body is not allowed for ${method.name} requests');
    }

    final encodedBody = body != null ? jsonEncode(body) : null;
    final maybeContentType = <String, String>{
      ...defaultHeaders,
      if (encodedBody != null) 'Content-Type': 'application/json',
      ...headerParameters,
    };
    // Just pass null to http if we have no headers to set.
    // This makes our calls match openapi (and thus our tests pass).
    final headers = maybeContentType.isEmpty ? null : maybeContentType;

    try {
      switch (method) {
        case Method.delete:
          return client.delete(uri, headers: headers);
        case Method.get:
          final withParams = uri.replace(
            queryParameters: {...baseUri.queryParameters, ...queryParameters},
          );
          return client.get(withParams, headers: headers);
        case Method.patch:
          return client.patch(uri, headers: headers, body: encodedBody);
        case Method.post:
          return client.post(uri, headers: headers, body: encodedBody);
        case Method.put:
          return client.put(uri, headers: headers, body: encodedBody);
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
