//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class WaypointTrait {
  /// Returns a new [WaypointTrait] instance.
  WaypointTrait({
    required this.symbol,
    required this.name,
    required this.description,
  });

  /// The unique identifier of the trait.
  WaypointTraitSymbolEnum symbol;

  /// The name of the trait.
  String name;

  /// A description of the trait.
  String description;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WaypointTrait &&
     other.symbol == symbol &&
     other.name == name &&
     other.description == description;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (symbol.hashCode) +
    (name.hashCode) +
    (description.hashCode);

  @override
  String toString() => 'WaypointTrait[symbol=$symbol, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'symbol'] = this.symbol;
      json[r'name'] = this.name;
      json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [WaypointTrait] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WaypointTrait? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "WaypointTrait[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "WaypointTrait[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WaypointTrait(
        symbol: WaypointTraitSymbolEnum.fromJson(json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<WaypointTrait>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WaypointTrait>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WaypointTrait.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WaypointTrait> mapFromJson(dynamic json) {
    final map = <String, WaypointTrait>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WaypointTrait.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WaypointTrait-objects as value to a dart map
  static Map<String, List<WaypointTrait>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WaypointTrait>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WaypointTrait.listFromJson(entry.value, growable: growable,);
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
class WaypointTraitSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const WaypointTraitSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const UNCHARTED = WaypointTraitSymbolEnum._(r'UNCHARTED');
  static const MARKETPLACE = WaypointTraitSymbolEnum._(r'MARKETPLACE');
  static const SHIPYARD = WaypointTraitSymbolEnum._(r'SHIPYARD');
  static const OUTPOST = WaypointTraitSymbolEnum._(r'OUTPOST');
  static const SCATTERED_SETTLEMENTS = WaypointTraitSymbolEnum._(r'SCATTERED_SETTLEMENTS');
  static const SPRAWLING_CITIES = WaypointTraitSymbolEnum._(r'SPRAWLING_CITIES');
  static const MEGA_STRUCTURES = WaypointTraitSymbolEnum._(r'MEGA_STRUCTURES');
  static const OVERCROWDED = WaypointTraitSymbolEnum._(r'OVERCROWDED');
  static const HIGH_TECH = WaypointTraitSymbolEnum._(r'HIGH_TECH');
  static const CORRUPT = WaypointTraitSymbolEnum._(r'CORRUPT');
  static const BUREAUCRATIC = WaypointTraitSymbolEnum._(r'BUREAUCRATIC');
  static const TRADING_HUB = WaypointTraitSymbolEnum._(r'TRADING_HUB');
  static const INDUSTRIAL = WaypointTraitSymbolEnum._(r'INDUSTRIAL');
  static const BLACK_MARKET = WaypointTraitSymbolEnum._(r'BLACK_MARKET');
  static const RESEARCH_FACILITY = WaypointTraitSymbolEnum._(r'RESEARCH_FACILITY');
  static const MILITARY_BASE = WaypointTraitSymbolEnum._(r'MILITARY_BASE');
  static const SURVEILLANCE_OUTPOST = WaypointTraitSymbolEnum._(r'SURVEILLANCE_OUTPOST');
  static const EXPLORATION_OUTPOST = WaypointTraitSymbolEnum._(r'EXPLORATION_OUTPOST');
  static const MINERAL_DEPOSITS = WaypointTraitSymbolEnum._(r'MINERAL_DEPOSITS');
  static const COMMON_METAL_DEPOSITS = WaypointTraitSymbolEnum._(r'COMMON_METAL_DEPOSITS');
  static const PRECIOUS_METAL_DEPOSITS = WaypointTraitSymbolEnum._(r'PRECIOUS_METAL_DEPOSITS');
  static const RARE_METAL_DEPOSITS = WaypointTraitSymbolEnum._(r'RARE_METAL_DEPOSITS');
  static const METHANE_POOLS = WaypointTraitSymbolEnum._(r'METHANE_POOLS');
  static const ICE_CRYSTALS = WaypointTraitSymbolEnum._(r'ICE_CRYSTALS');
  static const EXPLOSIVE_GASES = WaypointTraitSymbolEnum._(r'EXPLOSIVE_GASES');
  static const STRONG_MAGNETOSPHERE = WaypointTraitSymbolEnum._(r'STRONG_MAGNETOSPHERE');
  static const VIBRANT_AURORAS = WaypointTraitSymbolEnum._(r'VIBRANT_AURORAS');
  static const SALT_FLATS = WaypointTraitSymbolEnum._(r'SALT_FLATS');
  static const CANYONS = WaypointTraitSymbolEnum._(r'CANYONS');
  static const PERPETUAL_DAYLIGHT = WaypointTraitSymbolEnum._(r'PERPETUAL_DAYLIGHT');
  static const PERPETUAL_OVERCAST = WaypointTraitSymbolEnum._(r'PERPETUAL_OVERCAST');
  static const DRY_SEABEDS = WaypointTraitSymbolEnum._(r'DRY_SEABEDS');
  static const MAGMA_SEAS = WaypointTraitSymbolEnum._(r'MAGMA_SEAS');
  static const SUPERVOLCANOES = WaypointTraitSymbolEnum._(r'SUPERVOLCANOES');
  static const ASH_CLOUDS = WaypointTraitSymbolEnum._(r'ASH_CLOUDS');
  static const VAST_RUINS = WaypointTraitSymbolEnum._(r'VAST_RUINS');
  static const MUTATED_FLORA = WaypointTraitSymbolEnum._(r'MUTATED_FLORA');
  static const TERRAFORMED = WaypointTraitSymbolEnum._(r'TERRAFORMED');
  static const EXTREME_TEMPERATURES = WaypointTraitSymbolEnum._(r'EXTREME_TEMPERATURES');
  static const EXTREME_PRESSURE = WaypointTraitSymbolEnum._(r'EXTREME_PRESSURE');
  static const DIVERSE_LIFE = WaypointTraitSymbolEnum._(r'DIVERSE_LIFE');
  static const SCARCE_LIFE = WaypointTraitSymbolEnum._(r'SCARCE_LIFE');
  static const FOSSILS = WaypointTraitSymbolEnum._(r'FOSSILS');
  static const WEAK_GRAVITY = WaypointTraitSymbolEnum._(r'WEAK_GRAVITY');
  static const STRONG_GRAVITY = WaypointTraitSymbolEnum._(r'STRONG_GRAVITY');
  static const CRUSHING_GRAVITY = WaypointTraitSymbolEnum._(r'CRUSHING_GRAVITY');
  static const TOXIC_ATMOSPHERE = WaypointTraitSymbolEnum._(r'TOXIC_ATMOSPHERE');
  static const CORROSIVE_ATMOSPHERE = WaypointTraitSymbolEnum._(r'CORROSIVE_ATMOSPHERE');
  static const BREATHABLE_ATMOSPHERE = WaypointTraitSymbolEnum._(r'BREATHABLE_ATMOSPHERE');
  static const JOVIAN = WaypointTraitSymbolEnum._(r'JOVIAN');
  static const ROCKY = WaypointTraitSymbolEnum._(r'ROCKY');
  static const VOLCANIC = WaypointTraitSymbolEnum._(r'VOLCANIC');
  static const FROZEN = WaypointTraitSymbolEnum._(r'FROZEN');
  static const SWAMP = WaypointTraitSymbolEnum._(r'SWAMP');
  static const BARREN = WaypointTraitSymbolEnum._(r'BARREN');
  static const TEMPERATE = WaypointTraitSymbolEnum._(r'TEMPERATE');
  static const JUNGLE = WaypointTraitSymbolEnum._(r'JUNGLE');
  static const OCEAN = WaypointTraitSymbolEnum._(r'OCEAN');
  static const STRIPPED = WaypointTraitSymbolEnum._(r'STRIPPED');

  /// List of all possible values in this [enum][WaypointTraitSymbolEnum].
  static const values = <WaypointTraitSymbolEnum>[
    UNCHARTED,
    MARKETPLACE,
    SHIPYARD,
    OUTPOST,
    SCATTERED_SETTLEMENTS,
    SPRAWLING_CITIES,
    MEGA_STRUCTURES,
    OVERCROWDED,
    HIGH_TECH,
    CORRUPT,
    BUREAUCRATIC,
    TRADING_HUB,
    INDUSTRIAL,
    BLACK_MARKET,
    RESEARCH_FACILITY,
    MILITARY_BASE,
    SURVEILLANCE_OUTPOST,
    EXPLORATION_OUTPOST,
    MINERAL_DEPOSITS,
    COMMON_METAL_DEPOSITS,
    PRECIOUS_METAL_DEPOSITS,
    RARE_METAL_DEPOSITS,
    METHANE_POOLS,
    ICE_CRYSTALS,
    EXPLOSIVE_GASES,
    STRONG_MAGNETOSPHERE,
    VIBRANT_AURORAS,
    SALT_FLATS,
    CANYONS,
    PERPETUAL_DAYLIGHT,
    PERPETUAL_OVERCAST,
    DRY_SEABEDS,
    MAGMA_SEAS,
    SUPERVOLCANOES,
    ASH_CLOUDS,
    VAST_RUINS,
    MUTATED_FLORA,
    TERRAFORMED,
    EXTREME_TEMPERATURES,
    EXTREME_PRESSURE,
    DIVERSE_LIFE,
    SCARCE_LIFE,
    FOSSILS,
    WEAK_GRAVITY,
    STRONG_GRAVITY,
    CRUSHING_GRAVITY,
    TOXIC_ATMOSPHERE,
    CORROSIVE_ATMOSPHERE,
    BREATHABLE_ATMOSPHERE,
    JOVIAN,
    ROCKY,
    VOLCANIC,
    FROZEN,
    SWAMP,
    BARREN,
    TEMPERATE,
    JUNGLE,
    OCEAN,
    STRIPPED,
  ];

  static WaypointTraitSymbolEnum? fromJson(dynamic value) => WaypointTraitSymbolEnumTypeTransformer().decode(value);

  static List<WaypointTraitSymbolEnum>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WaypointTraitSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WaypointTraitSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WaypointTraitSymbolEnum] to String,
/// and [decode] dynamic data back to [WaypointTraitSymbolEnum].
class WaypointTraitSymbolEnumTypeTransformer {
  factory WaypointTraitSymbolEnumTypeTransformer() => _instance ??= const WaypointTraitSymbolEnumTypeTransformer._();

  const WaypointTraitSymbolEnumTypeTransformer._();

  String encode(WaypointTraitSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WaypointTraitSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WaypointTraitSymbolEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'UNCHARTED': return WaypointTraitSymbolEnum.UNCHARTED;
        case r'MARKETPLACE': return WaypointTraitSymbolEnum.MARKETPLACE;
        case r'SHIPYARD': return WaypointTraitSymbolEnum.SHIPYARD;
        case r'OUTPOST': return WaypointTraitSymbolEnum.OUTPOST;
        case r'SCATTERED_SETTLEMENTS': return WaypointTraitSymbolEnum.SCATTERED_SETTLEMENTS;
        case r'SPRAWLING_CITIES': return WaypointTraitSymbolEnum.SPRAWLING_CITIES;
        case r'MEGA_STRUCTURES': return WaypointTraitSymbolEnum.MEGA_STRUCTURES;
        case r'OVERCROWDED': return WaypointTraitSymbolEnum.OVERCROWDED;
        case r'HIGH_TECH': return WaypointTraitSymbolEnum.HIGH_TECH;
        case r'CORRUPT': return WaypointTraitSymbolEnum.CORRUPT;
        case r'BUREAUCRATIC': return WaypointTraitSymbolEnum.BUREAUCRATIC;
        case r'TRADING_HUB': return WaypointTraitSymbolEnum.TRADING_HUB;
        case r'INDUSTRIAL': return WaypointTraitSymbolEnum.INDUSTRIAL;
        case r'BLACK_MARKET': return WaypointTraitSymbolEnum.BLACK_MARKET;
        case r'RESEARCH_FACILITY': return WaypointTraitSymbolEnum.RESEARCH_FACILITY;
        case r'MILITARY_BASE': return WaypointTraitSymbolEnum.MILITARY_BASE;
        case r'SURVEILLANCE_OUTPOST': return WaypointTraitSymbolEnum.SURVEILLANCE_OUTPOST;
        case r'EXPLORATION_OUTPOST': return WaypointTraitSymbolEnum.EXPLORATION_OUTPOST;
        case r'MINERAL_DEPOSITS': return WaypointTraitSymbolEnum.MINERAL_DEPOSITS;
        case r'COMMON_METAL_DEPOSITS': return WaypointTraitSymbolEnum.COMMON_METAL_DEPOSITS;
        case r'PRECIOUS_METAL_DEPOSITS': return WaypointTraitSymbolEnum.PRECIOUS_METAL_DEPOSITS;
        case r'RARE_METAL_DEPOSITS': return WaypointTraitSymbolEnum.RARE_METAL_DEPOSITS;
        case r'METHANE_POOLS': return WaypointTraitSymbolEnum.METHANE_POOLS;
        case r'ICE_CRYSTALS': return WaypointTraitSymbolEnum.ICE_CRYSTALS;
        case r'EXPLOSIVE_GASES': return WaypointTraitSymbolEnum.EXPLOSIVE_GASES;
        case r'STRONG_MAGNETOSPHERE': return WaypointTraitSymbolEnum.STRONG_MAGNETOSPHERE;
        case r'VIBRANT_AURORAS': return WaypointTraitSymbolEnum.VIBRANT_AURORAS;
        case r'SALT_FLATS': return WaypointTraitSymbolEnum.SALT_FLATS;
        case r'CANYONS': return WaypointTraitSymbolEnum.CANYONS;
        case r'PERPETUAL_DAYLIGHT': return WaypointTraitSymbolEnum.PERPETUAL_DAYLIGHT;
        case r'PERPETUAL_OVERCAST': return WaypointTraitSymbolEnum.PERPETUAL_OVERCAST;
        case r'DRY_SEABEDS': return WaypointTraitSymbolEnum.DRY_SEABEDS;
        case r'MAGMA_SEAS': return WaypointTraitSymbolEnum.MAGMA_SEAS;
        case r'SUPERVOLCANOES': return WaypointTraitSymbolEnum.SUPERVOLCANOES;
        case r'ASH_CLOUDS': return WaypointTraitSymbolEnum.ASH_CLOUDS;
        case r'VAST_RUINS': return WaypointTraitSymbolEnum.VAST_RUINS;
        case r'MUTATED_FLORA': return WaypointTraitSymbolEnum.MUTATED_FLORA;
        case r'TERRAFORMED': return WaypointTraitSymbolEnum.TERRAFORMED;
        case r'EXTREME_TEMPERATURES': return WaypointTraitSymbolEnum.EXTREME_TEMPERATURES;
        case r'EXTREME_PRESSURE': return WaypointTraitSymbolEnum.EXTREME_PRESSURE;
        case r'DIVERSE_LIFE': return WaypointTraitSymbolEnum.DIVERSE_LIFE;
        case r'SCARCE_LIFE': return WaypointTraitSymbolEnum.SCARCE_LIFE;
        case r'FOSSILS': return WaypointTraitSymbolEnum.FOSSILS;
        case r'WEAK_GRAVITY': return WaypointTraitSymbolEnum.WEAK_GRAVITY;
        case r'STRONG_GRAVITY': return WaypointTraitSymbolEnum.STRONG_GRAVITY;
        case r'CRUSHING_GRAVITY': return WaypointTraitSymbolEnum.CRUSHING_GRAVITY;
        case r'TOXIC_ATMOSPHERE': return WaypointTraitSymbolEnum.TOXIC_ATMOSPHERE;
        case r'CORROSIVE_ATMOSPHERE': return WaypointTraitSymbolEnum.CORROSIVE_ATMOSPHERE;
        case r'BREATHABLE_ATMOSPHERE': return WaypointTraitSymbolEnum.BREATHABLE_ATMOSPHERE;
        case r'JOVIAN': return WaypointTraitSymbolEnum.JOVIAN;
        case r'ROCKY': return WaypointTraitSymbolEnum.ROCKY;
        case r'VOLCANIC': return WaypointTraitSymbolEnum.VOLCANIC;
        case r'FROZEN': return WaypointTraitSymbolEnum.FROZEN;
        case r'SWAMP': return WaypointTraitSymbolEnum.SWAMP;
        case r'BARREN': return WaypointTraitSymbolEnum.BARREN;
        case r'TEMPERATE': return WaypointTraitSymbolEnum.TEMPERATE;
        case r'JUNGLE': return WaypointTraitSymbolEnum.JUNGLE;
        case r'OCEAN': return WaypointTraitSymbolEnum.OCEAN;
        case r'STRIPPED': return WaypointTraitSymbolEnum.STRIPPED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WaypointTraitSymbolEnumTypeTransformer] instance.
  static WaypointTraitSymbolEnumTypeTransformer? _instance;
}


