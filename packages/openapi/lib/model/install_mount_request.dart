class InstallMountRequest {
  InstallMountRequest({required this.symbol});

  factory InstallMountRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return InstallMountRequest(symbol: json['symbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static InstallMountRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return InstallMountRequest.fromJson(json);
  }

  String symbol;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol};
  }

  @override
  int get hashCode => symbol.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstallMountRequest && symbol == other.symbol;
  }
}
