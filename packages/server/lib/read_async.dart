import 'package:dart_frog/dart_frog.dart';

/// Convenience extension to read an object of type [T] from the request context
/// asynchronously. This is useful when you need to read an object that is
/// created asynchronously, such as a database connection or an HTTP client.
extension ReadAsync on RequestContext {
  /// Reads an object of type [T] from the request context asynchronously.
  Future<T> readAsync<T extends Object>() => read<Future<T>>();
}

/// A type alias for a JSON object, represented as a map with string keys and
/// dynamic values. This is commonly used for JSON data structures in Dart.
typedef Json = Map<String, dynamic>;
