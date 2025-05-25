class RemoveMountRequest {
  RemoveMountRequest({required this.symbol});

  factory RemoveMountRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RemoveMountRequest(symbol: json['symbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RemoveMountRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RemoveMountRequest.fromJson(json);
  }

  String symbol;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol};
  }
}
