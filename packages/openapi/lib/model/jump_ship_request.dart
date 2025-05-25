class JumpShipRequest {
  JumpShipRequest({required this.waypointSymbol});

  factory JumpShipRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return JumpShipRequest(waypointSymbol: json['waypointSymbol'] as String);
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static JumpShipRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return JumpShipRequest.fromJson(json);
  }

  String waypointSymbol;

  Map<String, dynamic> toJson() {
    return {'waypointSymbol': waypointSymbol};
  }
}
