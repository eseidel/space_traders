enum ShipRefineRequestProduce {
  iron._('IRON'),
  copper._('COPPER'),
  silver._('SILVER'),
  gold._('GOLD'),
  aluminum._('ALUMINUM'),
  platinum._('PLATINUM'),
  uranite._('URANITE'),
  meritium._('MERITIUM'),
  fuel._('FUEL');

  const ShipRefineRequestProduce._(this.value);

  factory ShipRefineRequestProduce.fromJson(String json) {
    return ShipRefineRequestProduce.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException(
        'Unknown ShipRefineRequestProduce value: $json',
      ),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefineRequestProduce? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return ShipRefineRequestProduce.fromJson(json);
  }

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
