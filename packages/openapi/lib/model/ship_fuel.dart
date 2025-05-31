import 'package:openapi/model/ship_fuel_consumed.dart';

class ShipFuel {
  ShipFuel({required this.current, required this.capacity, this.consumed});

  factory ShipFuel.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipFuel(
      current: json['current'] as int,
      capacity: json['capacity'] as int,
      consumed: ShipFuelConsumed.maybeFromJson(
        json['consumed'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipFuel? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipFuel.fromJson(json);
  }

  int current;
  int capacity;
  ShipFuelConsumed? consumed;

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'capacity': capacity,
      'consumed': consumed?.toJson(),
    };
  }

  @override
  int get hashCode => Object.hash(current, capacity, consumed);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipFuel &&
        current == other.current &&
        capacity == other.capacity &&
        consumed == other.consumed;
  }
}
