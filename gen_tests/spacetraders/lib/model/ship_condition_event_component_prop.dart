enum ShipConditionEventComponentProp {
  frame._('FRAME'),
  reactor._('REACTOR'),
  engine._('ENGINE');

  const ShipConditionEventComponentProp._(this.value);

  factory ShipConditionEventComponentProp.fromJson(String json) {
    return ShipConditionEventComponentProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown ShipConditionEventComponentProp value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipConditionEventComponentProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipConditionEventComponentProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
