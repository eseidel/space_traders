//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The symbol of the faction.
class FactionSymbols {
  /// Instantiate a new enum with the provided [value].
  const FactionSymbols._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const COSMIC = FactionSymbols._(r'COSMIC');
  static const VOID = FactionSymbols._(r'VOID');
  static const GALACTIC = FactionSymbols._(r'GALACTIC');
  static const QUANTUM = FactionSymbols._(r'QUANTUM');
  static const DOMINION = FactionSymbols._(r'DOMINION');
  static const ASTRO = FactionSymbols._(r'ASTRO');
  static const CORSAIRS = FactionSymbols._(r'CORSAIRS');
  static const OBSIDIAN = FactionSymbols._(r'OBSIDIAN');
  static const AEGIS = FactionSymbols._(r'AEGIS');
  static const UNITED = FactionSymbols._(r'UNITED');
  static const SOLITARY = FactionSymbols._(r'SOLITARY');
  static const COBALT = FactionSymbols._(r'COBALT');
  static const OMEGA = FactionSymbols._(r'OMEGA');
  static const ECHO = FactionSymbols._(r'ECHO');
  static const LORDS = FactionSymbols._(r'LORDS');
  static const CULT = FactionSymbols._(r'CULT');
  static const ANCIENTS = FactionSymbols._(r'ANCIENTS');
  static const SHADOW = FactionSymbols._(r'SHADOW');
  static const ETHEREAL = FactionSymbols._(r'ETHEREAL');

  /// List of all possible values in this [enum][FactionSymbols].
  static const values = <FactionSymbols>[
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

  static FactionSymbols? fromJson(dynamic value) =>
      FactionSymbolsTypeTransformer().decode(value);

  static List<FactionSymbols>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FactionSymbols>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FactionSymbols.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FactionSymbols] to String,
/// and [decode] dynamic data back to [FactionSymbols].
class FactionSymbolsTypeTransformer {
  factory FactionSymbolsTypeTransformer() =>
      _instance ??= const FactionSymbolsTypeTransformer._();

  const FactionSymbolsTypeTransformer._();

  String encode(FactionSymbols data) => data.value;

  /// Decodes a [dynamic value][data] to a FactionSymbols.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FactionSymbols? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'COSMIC':
          return FactionSymbols.COSMIC;
        case r'VOID':
          return FactionSymbols.VOID;
        case r'GALACTIC':
          return FactionSymbols.GALACTIC;
        case r'QUANTUM':
          return FactionSymbols.QUANTUM;
        case r'DOMINION':
          return FactionSymbols.DOMINION;
        case r'ASTRO':
          return FactionSymbols.ASTRO;
        case r'CORSAIRS':
          return FactionSymbols.CORSAIRS;
        case r'OBSIDIAN':
          return FactionSymbols.OBSIDIAN;
        case r'AEGIS':
          return FactionSymbols.AEGIS;
        case r'UNITED':
          return FactionSymbols.UNITED;
        case r'SOLITARY':
          return FactionSymbols.SOLITARY;
        case r'COBALT':
          return FactionSymbols.COBALT;
        case r'OMEGA':
          return FactionSymbols.OMEGA;
        case r'ECHO':
          return FactionSymbols.ECHO;
        case r'LORDS':
          return FactionSymbols.LORDS;
        case r'CULT':
          return FactionSymbols.CULT;
        case r'ANCIENTS':
          return FactionSymbols.ANCIENTS;
        case r'SHADOW':
          return FactionSymbols.SHADOW;
        case r'ETHEREAL':
          return FactionSymbols.ETHEREAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [FactionSymbolsTypeTransformer] instance.
  static FactionSymbolsTypeTransformer? _instance;
}
