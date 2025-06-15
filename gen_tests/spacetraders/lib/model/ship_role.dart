enum ShipRole {
  fabricator._('FABRICATOR'),
  harvester._('HARVESTER'),
  hauler._('HAULER'),
  interceptor._('INTERCEPTOR'),
  excavator._('EXCAVATOR'),
  transport._('TRANSPORT'),
  repair._('REPAIR'),
  surveyor._('SURVEYOR'),
  command._('COMMAND'),
  carrier._('CARRIER'),
  patrol._('PATROL'),
  satellite._('SATELLITE'),
  explorer._('EXPLORER'),
  refinery._('REFINERY');

  const ShipRole._(this.value);

  factory ShipRole.fromJson(String json) {
    return ShipRole.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown ShipRole value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRole? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipRole.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
