enum FactionSymbol {
  cosmic._('COSMIC'),
  void_._('VOID'),
  galactic._('GALACTIC'),
  quantum._('QUANTUM'),
  dominion._('DOMINION'),
  astro._('ASTRO'),
  corsairs._('CORSAIRS'),
  obsidian._('OBSIDIAN'),
  aegis._('AEGIS'),
  united._('UNITED'),
  solitary._('SOLITARY'),
  cobalt._('COBALT'),
  omega._('OMEGA'),
  echo._('ECHO'),
  lords._('LORDS'),
  cult._('CULT'),
  ancients._('ANCIENTS'),
  shadow._('SHADOW'),
  ethereal._('ETHEREAL');

  const FactionSymbol._(this.value);

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

  final String value;

  String toJson() => value;

  @override
  String toString() => value;
}
