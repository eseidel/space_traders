import 'package:http/http.dart';

/// Request queued for later execution.
class QueuedRequest {
  /// Creates a new [QueuedRequest].
  const QueuedRequest({
    required this.method,
    required this.url,
    required this.body,
    required this.headers,
  });

  /// Creates an empty [QueuedRequest] with the given [url].
  factory QueuedRequest.empty(String url) {
    return QueuedRequest(method: 'GET', url: url, body: '', headers: {});
  }

  /// Creates a [QueuedRequest] from json.
  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      method: json['method'] as String,
      url: json['url'] as String,
      body: json['body'] as String,
      headers: (json['headers'] as Map<String, dynamic>).cast(),
    );
  }

  /// Converts this to json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'method': method,
      'url': url,
      'body': body,
      'headers': headers,
    };
  }

  /// HTTP method of the request.
  final String method;

  /// URL of the request.
  final String url;

  /// Body of the request.
  final String body;

  /// Headers of the request.
  final Map<String, String> headers;
}

/// Response queued for later execution.
class QueuedResponse {
  /// Creates a new [QueuedResponse].
  QueuedResponse({
    required this.body,
    required this.statusCode,
    required this.headers,
  });

  /// Creates a [QueuedResponse] from json.
  factory QueuedResponse.fromJson(Map<String, dynamic> json) {
    return QueuedResponse(
      body: json['body'] as String,
      statusCode: json['statusCode'] as int,
      headers: (json['headers'] as Map<String, dynamic>).cast(),
    );
  }

  /// Creates a [QueuedResponse] from a [Response].
  factory QueuedResponse.fromResponse(Response response) {
    return QueuedResponse(
      body: response.body,
      statusCode: response.statusCode,
      headers: response.headers,
    );
  }

  /// Body of the response.
  final String body;

  /// Status code of the response.
  final int statusCode;

  /// Headers of the response.
  final Map<String, String> headers;

  /// Converts this to a [Response].
  Response toResponse() => Response(body, statusCode, headers: headers);

  /// Converts this to json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'body': body,
      'statusCode': statusCode,
      'headers': headers,
    };
  }
}
