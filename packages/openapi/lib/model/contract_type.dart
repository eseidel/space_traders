/// Type of contract.
enum ContractType {
  PROCUREMENT._('PROCUREMENT'),
  TRANSPORT._('TRANSPORT'),
  SHUTTLE._('SHUTTLE');

  const ContractType._(this.value);

  /// Creates a ContractType from a json string.
  factory ContractType.fromJson(String json) {
    return ContractType.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown ContractType value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ContractType? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ContractType.fromJson(json);
  }

  /// The value of the enum, as a string.  This is the exact value
  /// from the OpenAPI spec and will be used for network transport.
  final String value;

  /// Converts the enum to a json string.
  String toJson() => value;

  /// Returns the string value of the enum.
  @override
  String toString() => value;
}
