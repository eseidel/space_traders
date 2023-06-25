//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class FactionTrait {
  /// Returns a new [FactionTrait] instance.
  FactionTrait({
    required this.symbol,
    required this.name,
    required this.description,
  });

  /// The unique identifier of the trait.
  FactionTraitSymbolEnum symbol;

  /// The name of the trait.
  String name;

  /// A description of the trait.
  String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FactionTrait &&
          other.symbol == symbol &&
          other.name == name &&
          other.description == description;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (name.hashCode) + (description.hashCode);

  @override
  String toString() =>
      'FactionTrait[symbol=$symbol, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [FactionTrait] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FactionTrait? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "FactionTrait[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "FactionTrait[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FactionTrait(
        symbol: FactionTraitSymbolEnum.fromJson(json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<FactionTrait>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FactionTrait>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FactionTrait.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FactionTrait> mapFromJson(dynamic json) {
    final map = <String, FactionTrait>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FactionTrait.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FactionTrait-objects as value to a dart map
  static Map<String, List<FactionTrait>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FactionTrait>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FactionTrait.listFromJson(
          entry.value,
          growable: growable,
        );
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
    'name',
    'description',
  };
}

/// The unique identifier of the trait.
class FactionTraitSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const FactionTraitSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BUREAUCRATIC = FactionTraitSymbolEnum._(r'BUREAUCRATIC');
  static const SECRETIVE = FactionTraitSymbolEnum._(r'SECRETIVE');
  static const CAPITALISTIC = FactionTraitSymbolEnum._(r'CAPITALISTIC');
  static const INDUSTRIOUS = FactionTraitSymbolEnum._(r'INDUSTRIOUS');
  static const PEACEFUL = FactionTraitSymbolEnum._(r'PEACEFUL');
  static const DISTRUSTFUL = FactionTraitSymbolEnum._(r'DISTRUSTFUL');
  static const WELCOMING = FactionTraitSymbolEnum._(r'WELCOMING');
  static const SMUGGLERS = FactionTraitSymbolEnum._(r'SMUGGLERS');
  static const SCAVENGERS = FactionTraitSymbolEnum._(r'SCAVENGERS');
  static const REBELLIOUS = FactionTraitSymbolEnum._(r'REBELLIOUS');
  static const EXILES = FactionTraitSymbolEnum._(r'EXILES');
  static const PIRATES = FactionTraitSymbolEnum._(r'PIRATES');
  static const RAIDERS = FactionTraitSymbolEnum._(r'RAIDERS');
  static const CLAN = FactionTraitSymbolEnum._(r'CLAN');
  static const GUILD = FactionTraitSymbolEnum._(r'GUILD');
  static const DOMINION = FactionTraitSymbolEnum._(r'DOMINION');
  static const FRINGE = FactionTraitSymbolEnum._(r'FRINGE');
  static const FORSAKEN = FactionTraitSymbolEnum._(r'FORSAKEN');
  static const ISOLATED = FactionTraitSymbolEnum._(r'ISOLATED');
  static const LOCALIZED = FactionTraitSymbolEnum._(r'LOCALIZED');
  static const ESTABLISHED = FactionTraitSymbolEnum._(r'ESTABLISHED');
  static const NOTABLE = FactionTraitSymbolEnum._(r'NOTABLE');
  static const DOMINANT = FactionTraitSymbolEnum._(r'DOMINANT');
  static const INESCAPABLE = FactionTraitSymbolEnum._(r'INESCAPABLE');
  static const INNOVATIVE = FactionTraitSymbolEnum._(r'INNOVATIVE');
  static const BOLD = FactionTraitSymbolEnum._(r'BOLD');
  static const VISIONARY = FactionTraitSymbolEnum._(r'VISIONARY');
  static const CURIOUS = FactionTraitSymbolEnum._(r'CURIOUS');
  static const DARING = FactionTraitSymbolEnum._(r'DARING');
  static const EXPLORATORY = FactionTraitSymbolEnum._(r'EXPLORATORY');
  static const RESOURCEFUL = FactionTraitSymbolEnum._(r'RESOURCEFUL');
  static const FLEXIBLE = FactionTraitSymbolEnum._(r'FLEXIBLE');
  static const COOPERATIVE = FactionTraitSymbolEnum._(r'COOPERATIVE');
  static const UNITED = FactionTraitSymbolEnum._(r'UNITED');
  static const STRATEGIC = FactionTraitSymbolEnum._(r'STRATEGIC');
  static const INTELLIGENT = FactionTraitSymbolEnum._(r'INTELLIGENT');
  static const RESEARCH_FOCUSED = FactionTraitSymbolEnum._(r'RESEARCH_FOCUSED');
  static const COLLABORATIVE = FactionTraitSymbolEnum._(r'COLLABORATIVE');
  static const PROGRESSIVE = FactionTraitSymbolEnum._(r'PROGRESSIVE');
  static const MILITARISTIC = FactionTraitSymbolEnum._(r'MILITARISTIC');
  static const TECHNOLOGICALLY_ADVANCED =
      FactionTraitSymbolEnum._(r'TECHNOLOGICALLY_ADVANCED');
  static const AGGRESSIVE = FactionTraitSymbolEnum._(r'AGGRESSIVE');
  static const IMPERIALISTIC = FactionTraitSymbolEnum._(r'IMPERIALISTIC');
  static const TREASURE_HUNTERS = FactionTraitSymbolEnum._(r'TREASURE_HUNTERS');
  static const DEXTEROUS = FactionTraitSymbolEnum._(r'DEXTEROUS');
  static const UNPREDICTABLE = FactionTraitSymbolEnum._(r'UNPREDICTABLE');
  static const BRUTAL = FactionTraitSymbolEnum._(r'BRUTAL');
  static const FLEETING = FactionTraitSymbolEnum._(r'FLEETING');
  static const ADAPTABLE = FactionTraitSymbolEnum._(r'ADAPTABLE');
  static const SELF_SUFFICIENT = FactionTraitSymbolEnum._(r'SELF_SUFFICIENT');
  static const DEFENSIVE = FactionTraitSymbolEnum._(r'DEFENSIVE');
  static const PROUD = FactionTraitSymbolEnum._(r'PROUD');
  static const DIVERSE = FactionTraitSymbolEnum._(r'DIVERSE');
  static const INDEPENDENT = FactionTraitSymbolEnum._(r'INDEPENDENT');
  static const SELF_INTERESTED = FactionTraitSymbolEnum._(r'SELF_INTERESTED');
  static const FRAGMENTED = FactionTraitSymbolEnum._(r'FRAGMENTED');
  static const COMMERCIAL = FactionTraitSymbolEnum._(r'COMMERCIAL');
  static const FREE_MARKETS = FactionTraitSymbolEnum._(r'FREE_MARKETS');
  static const ENTREPRENEURIAL = FactionTraitSymbolEnum._(r'ENTREPRENEURIAL');

  /// List of all possible values in this [enum][FactionTraitSymbolEnum].
  static const values = <FactionTraitSymbolEnum>[
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

  static FactionTraitSymbolEnum? fromJson(dynamic value) =>
      FactionTraitSymbolEnumTypeTransformer().decode(value);

  static List<FactionTraitSymbolEnum>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FactionTraitSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FactionTraitSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FactionTraitSymbolEnum] to String,
/// and [decode] dynamic data back to [FactionTraitSymbolEnum].
class FactionTraitSymbolEnumTypeTransformer {
  factory FactionTraitSymbolEnumTypeTransformer() =>
      _instance ??= const FactionTraitSymbolEnumTypeTransformer._();

  const FactionTraitSymbolEnumTypeTransformer._();

  String encode(FactionTraitSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a FactionTraitSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FactionTraitSymbolEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BUREAUCRATIC':
          return FactionTraitSymbolEnum.BUREAUCRATIC;
        case r'SECRETIVE':
          return FactionTraitSymbolEnum.SECRETIVE;
        case r'CAPITALISTIC':
          return FactionTraitSymbolEnum.CAPITALISTIC;
        case r'INDUSTRIOUS':
          return FactionTraitSymbolEnum.INDUSTRIOUS;
        case r'PEACEFUL':
          return FactionTraitSymbolEnum.PEACEFUL;
        case r'DISTRUSTFUL':
          return FactionTraitSymbolEnum.DISTRUSTFUL;
        case r'WELCOMING':
          return FactionTraitSymbolEnum.WELCOMING;
        case r'SMUGGLERS':
          return FactionTraitSymbolEnum.SMUGGLERS;
        case r'SCAVENGERS':
          return FactionTraitSymbolEnum.SCAVENGERS;
        case r'REBELLIOUS':
          return FactionTraitSymbolEnum.REBELLIOUS;
        case r'EXILES':
          return FactionTraitSymbolEnum.EXILES;
        case r'PIRATES':
          return FactionTraitSymbolEnum.PIRATES;
        case r'RAIDERS':
          return FactionTraitSymbolEnum.RAIDERS;
        case r'CLAN':
          return FactionTraitSymbolEnum.CLAN;
        case r'GUILD':
          return FactionTraitSymbolEnum.GUILD;
        case r'DOMINION':
          return FactionTraitSymbolEnum.DOMINION;
        case r'FRINGE':
          return FactionTraitSymbolEnum.FRINGE;
        case r'FORSAKEN':
          return FactionTraitSymbolEnum.FORSAKEN;
        case r'ISOLATED':
          return FactionTraitSymbolEnum.ISOLATED;
        case r'LOCALIZED':
          return FactionTraitSymbolEnum.LOCALIZED;
        case r'ESTABLISHED':
          return FactionTraitSymbolEnum.ESTABLISHED;
        case r'NOTABLE':
          return FactionTraitSymbolEnum.NOTABLE;
        case r'DOMINANT':
          return FactionTraitSymbolEnum.DOMINANT;
        case r'INESCAPABLE':
          return FactionTraitSymbolEnum.INESCAPABLE;
        case r'INNOVATIVE':
          return FactionTraitSymbolEnum.INNOVATIVE;
        case r'BOLD':
          return FactionTraitSymbolEnum.BOLD;
        case r'VISIONARY':
          return FactionTraitSymbolEnum.VISIONARY;
        case r'CURIOUS':
          return FactionTraitSymbolEnum.CURIOUS;
        case r'DARING':
          return FactionTraitSymbolEnum.DARING;
        case r'EXPLORATORY':
          return FactionTraitSymbolEnum.EXPLORATORY;
        case r'RESOURCEFUL':
          return FactionTraitSymbolEnum.RESOURCEFUL;
        case r'FLEXIBLE':
          return FactionTraitSymbolEnum.FLEXIBLE;
        case r'COOPERATIVE':
          return FactionTraitSymbolEnum.COOPERATIVE;
        case r'UNITED':
          return FactionTraitSymbolEnum.UNITED;
        case r'STRATEGIC':
          return FactionTraitSymbolEnum.STRATEGIC;
        case r'INTELLIGENT':
          return FactionTraitSymbolEnum.INTELLIGENT;
        case r'RESEARCH_FOCUSED':
          return FactionTraitSymbolEnum.RESEARCH_FOCUSED;
        case r'COLLABORATIVE':
          return FactionTraitSymbolEnum.COLLABORATIVE;
        case r'PROGRESSIVE':
          return FactionTraitSymbolEnum.PROGRESSIVE;
        case r'MILITARISTIC':
          return FactionTraitSymbolEnum.MILITARISTIC;
        case r'TECHNOLOGICALLY_ADVANCED':
          return FactionTraitSymbolEnum.TECHNOLOGICALLY_ADVANCED;
        case r'AGGRESSIVE':
          return FactionTraitSymbolEnum.AGGRESSIVE;
        case r'IMPERIALISTIC':
          return FactionTraitSymbolEnum.IMPERIALISTIC;
        case r'TREASURE_HUNTERS':
          return FactionTraitSymbolEnum.TREASURE_HUNTERS;
        case r'DEXTEROUS':
          return FactionTraitSymbolEnum.DEXTEROUS;
        case r'UNPREDICTABLE':
          return FactionTraitSymbolEnum.UNPREDICTABLE;
        case r'BRUTAL':
          return FactionTraitSymbolEnum.BRUTAL;
        case r'FLEETING':
          return FactionTraitSymbolEnum.FLEETING;
        case r'ADAPTABLE':
          return FactionTraitSymbolEnum.ADAPTABLE;
        case r'SELF_SUFFICIENT':
          return FactionTraitSymbolEnum.SELF_SUFFICIENT;
        case r'DEFENSIVE':
          return FactionTraitSymbolEnum.DEFENSIVE;
        case r'PROUD':
          return FactionTraitSymbolEnum.PROUD;
        case r'DIVERSE':
          return FactionTraitSymbolEnum.DIVERSE;
        case r'INDEPENDENT':
          return FactionTraitSymbolEnum.INDEPENDENT;
        case r'SELF_INTERESTED':
          return FactionTraitSymbolEnum.SELF_INTERESTED;
        case r'FRAGMENTED':
          return FactionTraitSymbolEnum.FRAGMENTED;
        case r'COMMERCIAL':
          return FactionTraitSymbolEnum.COMMERCIAL;
        case r'FREE_MARKETS':
          return FactionTraitSymbolEnum.FREE_MARKETS;
        case r'ENTREPRENEURIAL':
          return FactionTraitSymbolEnum.ENTREPRENEURIAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [FactionTraitSymbolEnumTypeTransformer] instance.
  static FactionTraitSymbolEnumTypeTransformer? _instance;
}
