enum OrderStatusProp {
  placed._('placed'),
  approved._('approved'),
  delivered._('delivered');

  const OrderStatusProp._(this.value);

  factory OrderStatusProp.fromJson(String json) {
    return OrderStatusProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () =>
          throw FormatException('Unknown OrderStatusProp value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static OrderStatusProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return OrderStatusProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
