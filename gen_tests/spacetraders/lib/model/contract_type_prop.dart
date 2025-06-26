enum ContractTypeProp {
  procurement._('PROCUREMENT'),
  transport._('TRANSPORT'),
  shuttle._('SHUTTLE');

  const ContractTypeProp._(this.value);

  factory ContractTypeProp.fromJson(String json) {
    return ContractTypeProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown ContractTypeProp value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ContractTypeProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ContractTypeProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
