class ShipRequirements {
  ShipRequirements({this.power, this.crew, this.slots});

  factory ShipRequirements.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipRequirements(
      power: json['power'] as int?,
      crew: json['crew'] as int?,
      slots: json['slots'] as int?,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRequirements? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipRequirements.fromJson(json);
  }

  int? power;
  int? crew;
  int? slots;

  Map<String, dynamic> toJson() {
    return {'power': power, 'crew': crew, 'slots': slots};
  }

  @override
  int get hashCode => Object.hash(power, crew, slots);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipRequirements &&
        power == other.power &&
        crew == other.crew &&
        slots == other.slots;
  }
}
