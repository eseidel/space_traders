/// The symbol of the faction.
enum FactionSymbol {
  COSMIC._('COSMIC'),
  VOID._('VOID'),
  GALACTIC._('GALACTIC'),
  QUANTUM._('QUANTUM'),
  DOMINION._('DOMINION'),
  ASTRO._('ASTRO'),
  CORSAIRS._('CORSAIRS'),
  OBSIDIAN._('OBSIDIAN'),
  AEGIS._('AEGIS'),
  UNITED._('UNITED'),
  SOLITARY._('SOLITARY'),
  COBALT._('COBALT'),
  OMEGA._('OMEGA'),
  ECHO._('ECHO'),
  LORDS._('LORDS'),
  CULT._('CULT'),
  ANCIENTS._('ANCIENTS'),
  SHADOW._('SHADOW'),
  ETHEREAL._('ETHEREAL');

  const FactionSymbol._(this.value);

  /// Creates a FactionSymbol from a json string.
  factory FactionSymbol.fromJson(String json) {
    return FactionSymbol.values.firstWhere(
      (value) => value.value == json,
      orElse: () => throw FormatException('Unknown FactionSymbol value: $json'),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static FactionSymbol? maybeFromJson(String? json) {
    if (json == null) {
      return null;
    }
    return FactionSymbol.fromJson(json);
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
