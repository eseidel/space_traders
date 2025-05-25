class ShipFuelConsumed {
  ShipFuelConsumed({required this.amount, required this.timestamp});

  factory ShipFuelConsumed.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipFuelConsumed(
      amount: json['amount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipFuelConsumed? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipFuelConsumed.fromJson(json);
  }

  int amount;
  DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'timestamp': timestamp.toIso8601String()};
  }
}
