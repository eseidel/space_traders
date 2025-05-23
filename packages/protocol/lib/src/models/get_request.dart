/// A request that can be converted to a query string.
// ignore: one_member_abstracts
abstract class GetRequest {
  /// Convert the request to a map of query parameters.
  Map<String, String?> toQueryParameters();
}
