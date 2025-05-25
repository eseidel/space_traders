class GetStatus200ResponseHealth {
  GetStatus200ResponseHealth({this.lastMarketUpdate});

  factory GetStatus200ResponseHealth.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return GetStatus200ResponseHealth(
      lastMarketUpdate: json['lastMarketUpdate'] as String?,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetStatus200ResponseHealth? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GetStatus200ResponseHealth.fromJson(json);
  }

  String? lastMarketUpdate;

  Map<String, dynamic> toJson() {
    return {'lastMarketUpdate': lastMarketUpdate};
  }
}
