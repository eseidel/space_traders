/// The type of good to produce out of the refining process.
enum ShipRefineRequestProduce {
  IRON._('IRON'),
  COPPER._('COPPER'),
  SILVER._('SILVER'),
  GOLD._('GOLD'),
  ALUMINUM._('ALUMINUM'),
  PLATINUM._('PLATINUM'),
  URANITE._('URANITE'),
  MERITIUM._('MERITIUM'),
  FUEL._('FUEL');

  const ShipRefineRequestProduce._(this.value);

  /// Creates a ShipRefineRequestProduce from a json string.
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

  /// The value of the enum, as a string.  This is the exact value
  /// from the OpenAPI spec and will be used for network transport.
  final String value;

  /// Converts the enum to a json string.
  String toJson() => value;

  /// Returns the string value of the enum.
  @override
  String toString() => value;
}
