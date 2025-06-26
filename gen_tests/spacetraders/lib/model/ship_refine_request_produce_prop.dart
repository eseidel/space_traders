enum ShipRefineRequestProduceProp {
  iron._('IRON'),
  copper._('COPPER'),
  silver._('SILVER'),
  gold._('GOLD'),
  aluminum._('ALUMINUM'),
  platinum._('PLATINUM'),
  uranite._('URANITE'),
  meritium._('MERITIUM'),
  fuel._('FUEL');

  const ShipRefineRequestProduceProp._(this.value);

  factory ShipRefineRequestProduceProp.fromJson(String json) {
    return ShipRefineRequestProduceProp.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown ShipRefineRequestProduceProp value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefineRequestProduceProp? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipRefineRequestProduceProp.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
