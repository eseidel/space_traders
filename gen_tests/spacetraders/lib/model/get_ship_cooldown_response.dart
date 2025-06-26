sealed class GetShipCooldownResponse {
  static GetShipCooldownResponse fromJson(dynamic jsonArg) {
    // Determine which schema to use based on the json.
    // TODO(eseidel): Implement this.
    throw UnimplementedError('GetShipCooldownResponse.fromJson');
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static GetShipCooldownResponse? maybeFromJson(dynamic json) {
    if (json == null) {
      return null;
    }
    return GetShipCooldownResponse.fromJson(json);
  }

  /// Require all subclasses to implement toJson.
  dynamic toJson();
}
