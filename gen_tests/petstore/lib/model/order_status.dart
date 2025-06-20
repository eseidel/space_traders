enum OrderStatus {
  placed._('placed'),
  approved._('approved'),
  delivered._('delivered');

  const OrderStatus._(this.value);

  factory OrderStatus.fromJson(String json) {
    return OrderStatus.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown OrderStatus value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static OrderStatus? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return OrderStatus.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
