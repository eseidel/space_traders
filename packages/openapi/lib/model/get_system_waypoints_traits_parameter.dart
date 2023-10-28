//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetSystemWaypointsTraitsParameter {
  /// Returns a new [GetSystemWaypointsTraitsParameter] instance.
  GetSystemWaypointsTraitsParameter({
    required this.symbol,
    required this.name,
    required this.description,
  });

  /// The unique identifier of the trait.
  GetSystemWaypointsTraitsParameterSymbolEnum symbol;

  /// The name of the trait.
  String name;

  /// A description of the trait.
  String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSystemWaypointsTraitsParameter &&
          other.symbol == symbol &&
          other.name == name &&
          other.description == description;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (name.hashCode) + (description.hashCode);

  @override
  String toString() =>
      'GetSystemWaypointsTraitsParameter[symbol=$symbol, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [GetSystemWaypointsTraitsParameter] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetSystemWaypointsTraitsParameter? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetSystemWaypointsTraitsParameter[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetSystemWaypointsTraitsParameter[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetSystemWaypointsTraitsParameter(
        symbol: GetSystemWaypointsTraitsParameterSymbolEnum.fromJson(
            json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<GetSystemWaypointsTraitsParameter> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetSystemWaypointsTraitsParameter>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetSystemWaypointsTraitsParameter.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetSystemWaypointsTraitsParameter> mapFromJson(
      dynamic json) {
    final map = <String, GetSystemWaypointsTraitsParameter>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetSystemWaypointsTraitsParameter.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetSystemWaypointsTraitsParameter-objects as value to a dart map
  static Map<String, List<GetSystemWaypointsTraitsParameter>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetSystemWaypointsTraitsParameter>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetSystemWaypointsTraitsParameter.listFromJson(
          entry.value,
          growable: growable,
        );
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
class GetSystemWaypointsTraitsParameterSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const GetSystemWaypointsTraitsParameterSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const UNCHARTED =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'UNCHARTED');
  static const UNDER_CONSTRUCTION =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'UNDER_CONSTRUCTION');
  static const MARKETPLACE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'MARKETPLACE');
  static const SHIPYARD =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SHIPYARD');
  static const OUTPOST =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'OUTPOST');
  static const SCATTERED_SETTLEMENTS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SCATTERED_SETTLEMENTS');
  static const SPRAWLING_CITIES =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SPRAWLING_CITIES');
  static const MEGA_STRUCTURES =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'MEGA_STRUCTURES');
  static const OVERCROWDED =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'OVERCROWDED');
  static const HIGH_TECH =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'HIGH_TECH');
  static const CORRUPT =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'CORRUPT');
  static const BUREAUCRATIC =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'BUREAUCRATIC');
  static const TRADING_HUB =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'TRADING_HUB');
  static const INDUSTRIAL =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'INDUSTRIAL');
  static const BLACK_MARKET =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'BLACK_MARKET');
  static const RESEARCH_FACILITY =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'RESEARCH_FACILITY');
  static const MILITARY_BASE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'MILITARY_BASE');
  static const SURVEILLANCE_OUTPOST =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SURVEILLANCE_OUTPOST');
  static const EXPLORATION_OUTPOST =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'EXPLORATION_OUTPOST');
  static const MINERAL_DEPOSITS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'MINERAL_DEPOSITS');
  static const COMMON_METAL_DEPOSITS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'COMMON_METAL_DEPOSITS');
  static const PRECIOUS_METAL_DEPOSITS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'PRECIOUS_METAL_DEPOSITS');
  static const RARE_METAL_DEPOSITS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'RARE_METAL_DEPOSITS');
  static const METHANE_POOLS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'METHANE_POOLS');
  static const ICE_CRYSTALS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'ICE_CRYSTALS');
  static const EXPLOSIVE_GASES =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'EXPLOSIVE_GASES');
  static const STRONG_MAGNETOSPHERE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'STRONG_MAGNETOSPHERE');
  static const VIBRANT_AURORAS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'VIBRANT_AURORAS');
  static const SALT_FLATS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SALT_FLATS');
  static const CANYONS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'CANYONS');
  static const PERPETUAL_DAYLIGHT =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'PERPETUAL_DAYLIGHT');
  static const PERPETUAL_OVERCAST =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'PERPETUAL_OVERCAST');
  static const DRY_SEABEDS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'DRY_SEABEDS');
  static const MAGMA_SEAS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'MAGMA_SEAS');
  static const SUPERVOLCANOES =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SUPERVOLCANOES');
  static const ASH_CLOUDS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'ASH_CLOUDS');
  static const VAST_RUINS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'VAST_RUINS');
  static const MUTATED_FLORA =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'MUTATED_FLORA');
  static const TERRAFORMED =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'TERRAFORMED');
  static const EXTREME_TEMPERATURES =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'EXTREME_TEMPERATURES');
  static const EXTREME_PRESSURE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'EXTREME_PRESSURE');
  static const DIVERSE_LIFE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'DIVERSE_LIFE');
  static const SCARCE_LIFE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SCARCE_LIFE');
  static const FOSSILS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'FOSSILS');
  static const WEAK_GRAVITY =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'WEAK_GRAVITY');
  static const STRONG_GRAVITY =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'STRONG_GRAVITY');
  static const CRUSHING_GRAVITY =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'CRUSHING_GRAVITY');
  static const TOXIC_ATMOSPHERE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'TOXIC_ATMOSPHERE');
  static const CORROSIVE_ATMOSPHERE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'CORROSIVE_ATMOSPHERE');
  static const BREATHABLE_ATMOSPHERE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'BREATHABLE_ATMOSPHERE');
  static const THIN_ATMOSPHERE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'THIN_ATMOSPHERE');
  static const JOVIAN =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'JOVIAN');
  static const ROCKY = GetSystemWaypointsTraitsParameterSymbolEnum._(r'ROCKY');
  static const VOLCANIC =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'VOLCANIC');
  static const FROZEN =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'FROZEN');
  static const SWAMP = GetSystemWaypointsTraitsParameterSymbolEnum._(r'SWAMP');
  static const BARREN =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'BARREN');
  static const TEMPERATE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'TEMPERATE');
  static const JUNGLE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'JUNGLE');
  static const OCEAN = GetSystemWaypointsTraitsParameterSymbolEnum._(r'OCEAN');
  static const RADIOACTIVE =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'RADIOACTIVE');
  static const MICRO_GRAVITY_ANOMALIES =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'MICRO_GRAVITY_ANOMALIES');
  static const DEBRIS_CLUSTER =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'DEBRIS_CLUSTER');
  static const DEEP_CRATERS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'DEEP_CRATERS');
  static const SHALLOW_CRATERS =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'SHALLOW_CRATERS');
  static const UNSTABLE_COMPOSITION =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'UNSTABLE_COMPOSITION');
  static const HOLLOWED_INTERIOR =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'HOLLOWED_INTERIOR');
  static const STRIPPED =
      GetSystemWaypointsTraitsParameterSymbolEnum._(r'STRIPPED');

  /// List of all possible values in this [enum][GetSystemWaypointsTraitsParameterSymbolEnum].
  static const values = <GetSystemWaypointsTraitsParameterSymbolEnum>[
    UNCHARTED,
    UNDER_CONSTRUCTION,
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
    THIN_ATMOSPHERE,
    JOVIAN,
    ROCKY,
    VOLCANIC,
    FROZEN,
    SWAMP,
    BARREN,
    TEMPERATE,
    JUNGLE,
    OCEAN,
    RADIOACTIVE,
    MICRO_GRAVITY_ANOMALIES,
    DEBRIS_CLUSTER,
    DEEP_CRATERS,
    SHALLOW_CRATERS,
    UNSTABLE_COMPOSITION,
    HOLLOWED_INTERIOR,
    STRIPPED,
  ];

  static GetSystemWaypointsTraitsParameterSymbolEnum? fromJson(dynamic value) =>
      GetSystemWaypointsTraitsParameterSymbolEnumTypeTransformer()
          .decode(value);

  static List<GetSystemWaypointsTraitsParameterSymbolEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetSystemWaypointsTraitsParameterSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetSystemWaypointsTraitsParameterSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [GetSystemWaypointsTraitsParameterSymbolEnum] to String,
/// and [decode] dynamic data back to [GetSystemWaypointsTraitsParameterSymbolEnum].
class GetSystemWaypointsTraitsParameterSymbolEnumTypeTransformer {
  factory GetSystemWaypointsTraitsParameterSymbolEnumTypeTransformer() =>
      _instance ??=
          const GetSystemWaypointsTraitsParameterSymbolEnumTypeTransformer._();

  const GetSystemWaypointsTraitsParameterSymbolEnumTypeTransformer._();

  String encode(GetSystemWaypointsTraitsParameterSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a GetSystemWaypointsTraitsParameterSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  GetSystemWaypointsTraitsParameterSymbolEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'UNCHARTED':
          return GetSystemWaypointsTraitsParameterSymbolEnum.UNCHARTED;
        case r'UNDER_CONSTRUCTION':
          return GetSystemWaypointsTraitsParameterSymbolEnum.UNDER_CONSTRUCTION;
        case r'MARKETPLACE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.MARKETPLACE;
        case r'SHIPYARD':
          return GetSystemWaypointsTraitsParameterSymbolEnum.SHIPYARD;
        case r'OUTPOST':
          return GetSystemWaypointsTraitsParameterSymbolEnum.OUTPOST;
        case r'SCATTERED_SETTLEMENTS':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .SCATTERED_SETTLEMENTS;
        case r'SPRAWLING_CITIES':
          return GetSystemWaypointsTraitsParameterSymbolEnum.SPRAWLING_CITIES;
        case r'MEGA_STRUCTURES':
          return GetSystemWaypointsTraitsParameterSymbolEnum.MEGA_STRUCTURES;
        case r'OVERCROWDED':
          return GetSystemWaypointsTraitsParameterSymbolEnum.OVERCROWDED;
        case r'HIGH_TECH':
          return GetSystemWaypointsTraitsParameterSymbolEnum.HIGH_TECH;
        case r'CORRUPT':
          return GetSystemWaypointsTraitsParameterSymbolEnum.CORRUPT;
        case r'BUREAUCRATIC':
          return GetSystemWaypointsTraitsParameterSymbolEnum.BUREAUCRATIC;
        case r'TRADING_HUB':
          return GetSystemWaypointsTraitsParameterSymbolEnum.TRADING_HUB;
        case r'INDUSTRIAL':
          return GetSystemWaypointsTraitsParameterSymbolEnum.INDUSTRIAL;
        case r'BLACK_MARKET':
          return GetSystemWaypointsTraitsParameterSymbolEnum.BLACK_MARKET;
        case r'RESEARCH_FACILITY':
          return GetSystemWaypointsTraitsParameterSymbolEnum.RESEARCH_FACILITY;
        case r'MILITARY_BASE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.MILITARY_BASE;
        case r'SURVEILLANCE_OUTPOST':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .SURVEILLANCE_OUTPOST;
        case r'EXPLORATION_OUTPOST':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .EXPLORATION_OUTPOST;
        case r'MINERAL_DEPOSITS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.MINERAL_DEPOSITS;
        case r'COMMON_METAL_DEPOSITS':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .COMMON_METAL_DEPOSITS;
        case r'PRECIOUS_METAL_DEPOSITS':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .PRECIOUS_METAL_DEPOSITS;
        case r'RARE_METAL_DEPOSITS':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .RARE_METAL_DEPOSITS;
        case r'METHANE_POOLS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.METHANE_POOLS;
        case r'ICE_CRYSTALS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.ICE_CRYSTALS;
        case r'EXPLOSIVE_GASES':
          return GetSystemWaypointsTraitsParameterSymbolEnum.EXPLOSIVE_GASES;
        case r'STRONG_MAGNETOSPHERE':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .STRONG_MAGNETOSPHERE;
        case r'VIBRANT_AURORAS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.VIBRANT_AURORAS;
        case r'SALT_FLATS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.SALT_FLATS;
        case r'CANYONS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.CANYONS;
        case r'PERPETUAL_DAYLIGHT':
          return GetSystemWaypointsTraitsParameterSymbolEnum.PERPETUAL_DAYLIGHT;
        case r'PERPETUAL_OVERCAST':
          return GetSystemWaypointsTraitsParameterSymbolEnum.PERPETUAL_OVERCAST;
        case r'DRY_SEABEDS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.DRY_SEABEDS;
        case r'MAGMA_SEAS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.MAGMA_SEAS;
        case r'SUPERVOLCANOES':
          return GetSystemWaypointsTraitsParameterSymbolEnum.SUPERVOLCANOES;
        case r'ASH_CLOUDS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.ASH_CLOUDS;
        case r'VAST_RUINS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.VAST_RUINS;
        case r'MUTATED_FLORA':
          return GetSystemWaypointsTraitsParameterSymbolEnum.MUTATED_FLORA;
        case r'TERRAFORMED':
          return GetSystemWaypointsTraitsParameterSymbolEnum.TERRAFORMED;
        case r'EXTREME_TEMPERATURES':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .EXTREME_TEMPERATURES;
        case r'EXTREME_PRESSURE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.EXTREME_PRESSURE;
        case r'DIVERSE_LIFE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.DIVERSE_LIFE;
        case r'SCARCE_LIFE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.SCARCE_LIFE;
        case r'FOSSILS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.FOSSILS;
        case r'WEAK_GRAVITY':
          return GetSystemWaypointsTraitsParameterSymbolEnum.WEAK_GRAVITY;
        case r'STRONG_GRAVITY':
          return GetSystemWaypointsTraitsParameterSymbolEnum.STRONG_GRAVITY;
        case r'CRUSHING_GRAVITY':
          return GetSystemWaypointsTraitsParameterSymbolEnum.CRUSHING_GRAVITY;
        case r'TOXIC_ATMOSPHERE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.TOXIC_ATMOSPHERE;
        case r'CORROSIVE_ATMOSPHERE':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .CORROSIVE_ATMOSPHERE;
        case r'BREATHABLE_ATMOSPHERE':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .BREATHABLE_ATMOSPHERE;
        case r'THIN_ATMOSPHERE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.THIN_ATMOSPHERE;
        case r'JOVIAN':
          return GetSystemWaypointsTraitsParameterSymbolEnum.JOVIAN;
        case r'ROCKY':
          return GetSystemWaypointsTraitsParameterSymbolEnum.ROCKY;
        case r'VOLCANIC':
          return GetSystemWaypointsTraitsParameterSymbolEnum.VOLCANIC;
        case r'FROZEN':
          return GetSystemWaypointsTraitsParameterSymbolEnum.FROZEN;
        case r'SWAMP':
          return GetSystemWaypointsTraitsParameterSymbolEnum.SWAMP;
        case r'BARREN':
          return GetSystemWaypointsTraitsParameterSymbolEnum.BARREN;
        case r'TEMPERATE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.TEMPERATE;
        case r'JUNGLE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.JUNGLE;
        case r'OCEAN':
          return GetSystemWaypointsTraitsParameterSymbolEnum.OCEAN;
        case r'RADIOACTIVE':
          return GetSystemWaypointsTraitsParameterSymbolEnum.RADIOACTIVE;
        case r'MICRO_GRAVITY_ANOMALIES':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .MICRO_GRAVITY_ANOMALIES;
        case r'DEBRIS_CLUSTER':
          return GetSystemWaypointsTraitsParameterSymbolEnum.DEBRIS_CLUSTER;
        case r'DEEP_CRATERS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.DEEP_CRATERS;
        case r'SHALLOW_CRATERS':
          return GetSystemWaypointsTraitsParameterSymbolEnum.SHALLOW_CRATERS;
        case r'UNSTABLE_COMPOSITION':
          return GetSystemWaypointsTraitsParameterSymbolEnum
              .UNSTABLE_COMPOSITION;
        case r'HOLLOWED_INTERIOR':
          return GetSystemWaypointsTraitsParameterSymbolEnum.HOLLOWED_INTERIOR;
        case r'STRIPPED':
          return GetSystemWaypointsTraitsParameterSymbolEnum.STRIPPED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [GetSystemWaypointsTraitsParameterSymbolEnumTypeTransformer] instance.
  static GetSystemWaypointsTraitsParameterSymbolEnumTypeTransformer? _instance;
}
