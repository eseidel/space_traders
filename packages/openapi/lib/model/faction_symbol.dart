//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The symbol of the faction.
class FactionSymbol {
  /// Instantiate a new enum with the provided [value].
  const FactionSymbol._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const COSMIC = FactionSymbol._(r'COSMIC');
  static const VOID = FactionSymbol._(r'VOID');
  static const GALACTIC = FactionSymbol._(r'GALACTIC');
  static const QUANTUM = FactionSymbol._(r'QUANTUM');
  static const DOMINION = FactionSymbol._(r'DOMINION');
  static const ASTRO = FactionSymbol._(r'ASTRO');
  static const CORSAIRS = FactionSymbol._(r'CORSAIRS');
  static const OBSIDIAN = FactionSymbol._(r'OBSIDIAN');
  static const AEGIS = FactionSymbol._(r'AEGIS');
  static const UNITED = FactionSymbol._(r'UNITED');
  static const SOLITARY = FactionSymbol._(r'SOLITARY');
  static const COBALT = FactionSymbol._(r'COBALT');
  static const OMEGA = FactionSymbol._(r'OMEGA');
  static const ECHO = FactionSymbol._(r'ECHO');
  static const LORDS = FactionSymbol._(r'LORDS');
  static const CULT = FactionSymbol._(r'CULT');
  static const ANCIENTS = FactionSymbol._(r'ANCIENTS');
  static const SHADOW = FactionSymbol._(r'SHADOW');
  static const ETHEREAL = FactionSymbol._(r'ETHEREAL');

  /// List of all possible values in this [enum][FactionSymbol].
  static const values = <FactionSymbol>[
    COSMIC,
    VOID,
    GALACTIC,
    QUANTUM,
    DOMINION,
    ASTRO,
    CORSAIRS,
    OBSIDIAN,
    AEGIS,
    UNITED,
    SOLITARY,
    COBALT,
    OMEGA,
    ECHO,
    LORDS,
    CULT,
    ANCIENTS,
    SHADOW,
    ETHEREAL,
  ];

  static FactionSymbol? fromJson(dynamic value) =>
      FactionSymbolTypeTransformer().decode(value);

  static List<FactionSymbol> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FactionSymbol>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FactionSymbol.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FactionSymbol] to String,
/// and [decode] dynamic data back to [FactionSymbol].
class FactionSymbolTypeTransformer {
  factory FactionSymbolTypeTransformer() =>
      _instance ??= const FactionSymbolTypeTransformer._();

  const FactionSymbolTypeTransformer._();

  String encode(FactionSymbol data) => data.value;

  /// Decodes a [dynamic value][data] to a FactionSymbol.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FactionSymbol? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'COSMIC':
          return FactionSymbol.COSMIC;
        case r'VOID':
          return FactionSymbol.VOID;
        case r'GALACTIC':
          return FactionSymbol.GALACTIC;
        case r'QUANTUM':
          return FactionSymbol.QUANTUM;
        case r'DOMINION':
          return FactionSymbol.DOMINION;
        case r'ASTRO':
          return FactionSymbol.ASTRO;
        case r'CORSAIRS':
          return FactionSymbol.CORSAIRS;
        case r'OBSIDIAN':
          return FactionSymbol.OBSIDIAN;
        case r'AEGIS':
          return FactionSymbol.AEGIS;
        case r'UNITED':
          return FactionSymbol.UNITED;
        case r'SOLITARY':
          return FactionSymbol.SOLITARY;
        case r'COBALT':
          return FactionSymbol.COBALT;
        case r'OMEGA':
          return FactionSymbol.OMEGA;
        case r'ECHO':
          return FactionSymbol.ECHO;
        case r'LORDS':
          return FactionSymbol.LORDS;
        case r'CULT':
          return FactionSymbol.CULT;
        case r'ANCIENTS':
          return FactionSymbol.ANCIENTS;
        case r'SHADOW':
          return FactionSymbol.SHADOW;
        case r'ETHEREAL':
          return FactionSymbol.ETHEREAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [FactionSymbolTypeTransformer] instance.
  static FactionSymbolTypeTransformer? _instance;
}
