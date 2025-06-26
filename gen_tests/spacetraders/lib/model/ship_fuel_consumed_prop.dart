import 'package:meta/meta.dart';

@immutable
class ShipFuelConsumedProp {
  const ShipFuelConsumedProp({required this.amount, required this.timestamp});

  factory ShipFuelConsumedProp.fromJson(Map<String, dynamic> json) {
    return ShipFuelConsumedProp(
      amount: json['amount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipFuelConsumedProp? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipFuelConsumedProp.fromJson(json);
  }

  final int amount;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'timestamp': timestamp.toIso8601String()};
  }

  @override
  int get hashCode => Object.hashAll([amount, timestamp]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipFuelConsumedProp &&
        amount == other.amount &&
        timestamp == other.timestamp;
  }
}
