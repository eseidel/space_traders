class RemoveShipModuleRequest {
  RemoveShipModuleRequest({required this.symbol});

  factory RemoveShipModuleRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return RemoveShipModuleRequest(symbol: json['symbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static RemoveShipModuleRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RemoveShipModuleRequest.fromJson(json);
  }

  String symbol;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol};
  }
}
