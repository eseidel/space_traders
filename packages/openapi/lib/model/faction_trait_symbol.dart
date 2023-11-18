//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

/// The unique identifier of the trait.
class FactionTraitSymbol {
  /// Instantiate a new enum with the provided [value].
  const FactionTraitSymbol._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BUREAUCRATIC = FactionTraitSymbol._(r'BUREAUCRATIC');
  static const SECRETIVE = FactionTraitSymbol._(r'SECRETIVE');
  static const CAPITALISTIC = FactionTraitSymbol._(r'CAPITALISTIC');
  static const INDUSTRIOUS = FactionTraitSymbol._(r'INDUSTRIOUS');
  static const PEACEFUL = FactionTraitSymbol._(r'PEACEFUL');
  static const DISTRUSTFUL = FactionTraitSymbol._(r'DISTRUSTFUL');
  static const WELCOMING = FactionTraitSymbol._(r'WELCOMING');
  static const SMUGGLERS = FactionTraitSymbol._(r'SMUGGLERS');
  static const SCAVENGERS = FactionTraitSymbol._(r'SCAVENGERS');
  static const REBELLIOUS = FactionTraitSymbol._(r'REBELLIOUS');
  static const EXILES = FactionTraitSymbol._(r'EXILES');
  static const PIRATES = FactionTraitSymbol._(r'PIRATES');
  static const RAIDERS = FactionTraitSymbol._(r'RAIDERS');
  static const CLAN = FactionTraitSymbol._(r'CLAN');
  static const GUILD = FactionTraitSymbol._(r'GUILD');
  static const DOMINION = FactionTraitSymbol._(r'DOMINION');
  static const FRINGE = FactionTraitSymbol._(r'FRINGE');
  static const FORSAKEN = FactionTraitSymbol._(r'FORSAKEN');
  static const ISOLATED = FactionTraitSymbol._(r'ISOLATED');
  static const LOCALIZED = FactionTraitSymbol._(r'LOCALIZED');
  static const ESTABLISHED = FactionTraitSymbol._(r'ESTABLISHED');
  static const NOTABLE = FactionTraitSymbol._(r'NOTABLE');
  static const DOMINANT = FactionTraitSymbol._(r'DOMINANT');
  static const INESCAPABLE = FactionTraitSymbol._(r'INESCAPABLE');
  static const INNOVATIVE = FactionTraitSymbol._(r'INNOVATIVE');
  static const BOLD = FactionTraitSymbol._(r'BOLD');
  static const VISIONARY = FactionTraitSymbol._(r'VISIONARY');
  static const CURIOUS = FactionTraitSymbol._(r'CURIOUS');
  static const DARING = FactionTraitSymbol._(r'DARING');
  static const EXPLORATORY = FactionTraitSymbol._(r'EXPLORATORY');
  static const RESOURCEFUL = FactionTraitSymbol._(r'RESOURCEFUL');
  static const FLEXIBLE = FactionTraitSymbol._(r'FLEXIBLE');
  static const COOPERATIVE = FactionTraitSymbol._(r'COOPERATIVE');
  static const UNITED = FactionTraitSymbol._(r'UNITED');
  static const STRATEGIC = FactionTraitSymbol._(r'STRATEGIC');
  static const INTELLIGENT = FactionTraitSymbol._(r'INTELLIGENT');
  static const RESEARCH_FOCUSED = FactionTraitSymbol._(r'RESEARCH_FOCUSED');
  static const COLLABORATIVE = FactionTraitSymbol._(r'COLLABORATIVE');
  static const PROGRESSIVE = FactionTraitSymbol._(r'PROGRESSIVE');
  static const MILITARISTIC = FactionTraitSymbol._(r'MILITARISTIC');
  static const TECHNOLOGICALLY_ADVANCED =
      FactionTraitSymbol._(r'TECHNOLOGICALLY_ADVANCED');
  static const AGGRESSIVE = FactionTraitSymbol._(r'AGGRESSIVE');
  static const IMPERIALISTIC = FactionTraitSymbol._(r'IMPERIALISTIC');
  static const TREASURE_HUNTERS = FactionTraitSymbol._(r'TREASURE_HUNTERS');
  static const DEXTEROUS = FactionTraitSymbol._(r'DEXTEROUS');
  static const UNPREDICTABLE = FactionTraitSymbol._(r'UNPREDICTABLE');
  static const BRUTAL = FactionTraitSymbol._(r'BRUTAL');
  static const FLEETING = FactionTraitSymbol._(r'FLEETING');
  static const ADAPTABLE = FactionTraitSymbol._(r'ADAPTABLE');
  static const SELF_SUFFICIENT = FactionTraitSymbol._(r'SELF_SUFFICIENT');
  static const DEFENSIVE = FactionTraitSymbol._(r'DEFENSIVE');
  static const PROUD = FactionTraitSymbol._(r'PROUD');
  static const DIVERSE = FactionTraitSymbol._(r'DIVERSE');
  static const INDEPENDENT = FactionTraitSymbol._(r'INDEPENDENT');
  static const SELF_INTERESTED = FactionTraitSymbol._(r'SELF_INTERESTED');
  static const FRAGMENTED = FactionTraitSymbol._(r'FRAGMENTED');
  static const COMMERCIAL = FactionTraitSymbol._(r'COMMERCIAL');
  static const FREE_MARKETS = FactionTraitSymbol._(r'FREE_MARKETS');
  static const ENTREPRENEURIAL = FactionTraitSymbol._(r'ENTREPRENEURIAL');

  /// List of all possible values in this [enum][FactionTraitSymbol].
  static const values = <FactionTraitSymbol>[
    BUREAUCRATIC,
    SECRETIVE,
    CAPITALISTIC,
    INDUSTRIOUS,
    PEACEFUL,
    DISTRUSTFUL,
    WELCOMING,
    SMUGGLERS,
    SCAVENGERS,
    REBELLIOUS,
    EXILES,
    PIRATES,
    RAIDERS,
    CLAN,
    GUILD,
    DOMINION,
    FRINGE,
    FORSAKEN,
    ISOLATED,
    LOCALIZED,
    ESTABLISHED,
    NOTABLE,
    DOMINANT,
    INESCAPABLE,
    INNOVATIVE,
    BOLD,
    VISIONARY,
    CURIOUS,
    DARING,
    EXPLORATORY,
    RESOURCEFUL,
    FLEXIBLE,
    COOPERATIVE,
    UNITED,
    STRATEGIC,
    INTELLIGENT,
    RESEARCH_FOCUSED,
    COLLABORATIVE,
    PROGRESSIVE,
    MILITARISTIC,
    TECHNOLOGICALLY_ADVANCED,
    AGGRESSIVE,
    IMPERIALISTIC,
    TREASURE_HUNTERS,
    DEXTEROUS,
    UNPREDICTABLE,
    BRUTAL,
    FLEETING,
    ADAPTABLE,
    SELF_SUFFICIENT,
    DEFENSIVE,
    PROUD,
    DIVERSE,
    INDEPENDENT,
    SELF_INTERESTED,
    FRAGMENTED,
    COMMERCIAL,
    FREE_MARKETS,
    ENTREPRENEURIAL,
  ];

  static FactionTraitSymbol? fromJson(dynamic value) =>
      FactionTraitSymbolTypeTransformer().decode(value);

  static List<FactionTraitSymbol> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FactionTraitSymbol>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FactionTraitSymbol.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FactionTraitSymbol] to String,
/// and [decode] dynamic data back to [FactionTraitSymbol].
class FactionTraitSymbolTypeTransformer {
  factory FactionTraitSymbolTypeTransformer() =>
      _instance ??= const FactionTraitSymbolTypeTransformer._();

  const FactionTraitSymbolTypeTransformer._();

  String encode(FactionTraitSymbol data) => data.value;

  /// Decodes a [dynamic value][data] to a FactionTraitSymbol.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FactionTraitSymbol? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BUREAUCRATIC':
          return FactionTraitSymbol.BUREAUCRATIC;
        case r'SECRETIVE':
          return FactionTraitSymbol.SECRETIVE;
        case r'CAPITALISTIC':
          return FactionTraitSymbol.CAPITALISTIC;
        case r'INDUSTRIOUS':
          return FactionTraitSymbol.INDUSTRIOUS;
        case r'PEACEFUL':
          return FactionTraitSymbol.PEACEFUL;
        case r'DISTRUSTFUL':
          return FactionTraitSymbol.DISTRUSTFUL;
        case r'WELCOMING':
          return FactionTraitSymbol.WELCOMING;
        case r'SMUGGLERS':
          return FactionTraitSymbol.SMUGGLERS;
        case r'SCAVENGERS':
          return FactionTraitSymbol.SCAVENGERS;
        case r'REBELLIOUS':
          return FactionTraitSymbol.REBELLIOUS;
        case r'EXILES':
          return FactionTraitSymbol.EXILES;
        case r'PIRATES':
          return FactionTraitSymbol.PIRATES;
        case r'RAIDERS':
          return FactionTraitSymbol.RAIDERS;
        case r'CLAN':
          return FactionTraitSymbol.CLAN;
        case r'GUILD':
          return FactionTraitSymbol.GUILD;
        case r'DOMINION':
          return FactionTraitSymbol.DOMINION;
        case r'FRINGE':
          return FactionTraitSymbol.FRINGE;
        case r'FORSAKEN':
          return FactionTraitSymbol.FORSAKEN;
        case r'ISOLATED':
          return FactionTraitSymbol.ISOLATED;
        case r'LOCALIZED':
          return FactionTraitSymbol.LOCALIZED;
        case r'ESTABLISHED':
          return FactionTraitSymbol.ESTABLISHED;
        case r'NOTABLE':
          return FactionTraitSymbol.NOTABLE;
        case r'DOMINANT':
          return FactionTraitSymbol.DOMINANT;
        case r'INESCAPABLE':
          return FactionTraitSymbol.INESCAPABLE;
        case r'INNOVATIVE':
          return FactionTraitSymbol.INNOVATIVE;
        case r'BOLD':
          return FactionTraitSymbol.BOLD;
        case r'VISIONARY':
          return FactionTraitSymbol.VISIONARY;
        case r'CURIOUS':
          return FactionTraitSymbol.CURIOUS;
        case r'DARING':
          return FactionTraitSymbol.DARING;
        case r'EXPLORATORY':
          return FactionTraitSymbol.EXPLORATORY;
        case r'RESOURCEFUL':
          return FactionTraitSymbol.RESOURCEFUL;
        case r'FLEXIBLE':
          return FactionTraitSymbol.FLEXIBLE;
        case r'COOPERATIVE':
          return FactionTraitSymbol.COOPERATIVE;
        case r'UNITED':
          return FactionTraitSymbol.UNITED;
        case r'STRATEGIC':
          return FactionTraitSymbol.STRATEGIC;
        case r'INTELLIGENT':
          return FactionTraitSymbol.INTELLIGENT;
        case r'RESEARCH_FOCUSED':
          return FactionTraitSymbol.RESEARCH_FOCUSED;
        case r'COLLABORATIVE':
          return FactionTraitSymbol.COLLABORATIVE;
        case r'PROGRESSIVE':
          return FactionTraitSymbol.PROGRESSIVE;
        case r'MILITARISTIC':
          return FactionTraitSymbol.MILITARISTIC;
        case r'TECHNOLOGICALLY_ADVANCED':
          return FactionTraitSymbol.TECHNOLOGICALLY_ADVANCED;
        case r'AGGRESSIVE':
          return FactionTraitSymbol.AGGRESSIVE;
        case r'IMPERIALISTIC':
          return FactionTraitSymbol.IMPERIALISTIC;
        case r'TREASURE_HUNTERS':
          return FactionTraitSymbol.TREASURE_HUNTERS;
        case r'DEXTEROUS':
          return FactionTraitSymbol.DEXTEROUS;
        case r'UNPREDICTABLE':
          return FactionTraitSymbol.UNPREDICTABLE;
        case r'BRUTAL':
          return FactionTraitSymbol.BRUTAL;
        case r'FLEETING':
          return FactionTraitSymbol.FLEETING;
        case r'ADAPTABLE':
          return FactionTraitSymbol.ADAPTABLE;
        case r'SELF_SUFFICIENT':
          return FactionTraitSymbol.SELF_SUFFICIENT;
        case r'DEFENSIVE':
          return FactionTraitSymbol.DEFENSIVE;
        case r'PROUD':
          return FactionTraitSymbol.PROUD;
        case r'DIVERSE':
          return FactionTraitSymbol.DIVERSE;
        case r'INDEPENDENT':
          return FactionTraitSymbol.INDEPENDENT;
        case r'SELF_INTERESTED':
          return FactionTraitSymbol.SELF_INTERESTED;
        case r'FRAGMENTED':
          return FactionTraitSymbol.FRAGMENTED;
        case r'COMMERCIAL':
          return FactionTraitSymbol.COMMERCIAL;
        case r'FREE_MARKETS':
          return FactionTraitSymbol.FREE_MARKETS;
        case r'ENTREPRENEURIAL':
          return FactionTraitSymbol.ENTREPRENEURIAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [FactionTraitSymbolTypeTransformer] instance.
  static FactionTraitSymbolTypeTransformer? _instance;
}
