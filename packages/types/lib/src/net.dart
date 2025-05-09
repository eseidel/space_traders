import 'dart:convert';

import 'package:http/http.dart' as http;

/// A type alias for a JSON object.
typedef Json = Map<String, dynamic>;

/// An extension on [http.Response] to decode the body as a JSON object.
extension JsonDecode on http.Response {
  /// Decodes the body of the response as a JSON object.
  Json get json => jsonDecode(body) as Json;
}
