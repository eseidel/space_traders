//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipReactor {
  /// Returns a new [ShipReactor] instance.
  ShipReactor({
    required this.symbol,
    required this.name,
    required this.description,
    required this.condition,
    required this.integrity,
    required this.powerOutput,
    required this.requirements,
  });

  /// Symbol of the reactor.
  ShipReactorSymbolEnum symbol;

  /// Name of the reactor.
  String name;

  /// Description of the reactor.
  String description;

  /// The repairable condition of a component. A value of 0 indicates the component needs significant repairs, while a value of 1 indicates the component is in near perfect condition. As the condition of a component is repaired, the overall integrity of the component decreases.
  ///
  /// Minimum value: 0
  /// Maximum value: 1
  double condition;

  /// The overall integrity of the component, which determines the performance of the component. A value of 0 indicates that the component is almost completely degraded, while a value of 1 indicates that the component is in near perfect condition. The integrity of the component is non-repairable, and represents permanent wear over time.
  ///
  /// Minimum value: 0
  /// Maximum value: 1
  double integrity;

  /// The amount of power provided by this reactor. The more power a reactor provides to the ship, the lower the cooldown it gets when using a module or mount that taxes the ship's power.
  ///
  /// Minimum value: 1
  int powerOutput;

  ShipRequirements requirements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipReactor &&
          other.symbol == symbol &&
          other.name == name &&
          other.description == description &&
          other.condition == condition &&
          other.integrity == integrity &&
          other.powerOutput == powerOutput &&
          other.requirements == requirements;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (name.hashCode) +
      (description.hashCode) +
      (condition.hashCode) +
      (integrity.hashCode) +
      (powerOutput.hashCode) +
      (requirements.hashCode);

  @override
  String toString() =>
      'ShipReactor[symbol=$symbol, name=$name, description=$description, condition=$condition, integrity=$integrity, powerOutput=$powerOutput, requirements=$requirements]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    json[r'condition'] = this.condition;
    json[r'integrity'] = this.integrity;
    json[r'powerOutput'] = this.powerOutput;
    json[r'requirements'] = this.requirements;
    return json;
  }

  /// Returns a new [ShipReactor] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipReactor? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipReactor[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipReactor[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipReactor(
        symbol: ShipReactorSymbolEnum.fromJson(json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        condition: mapValueOfType<double>(json, r'condition')!,
        integrity: mapValueOfType<double>(json, r'integrity')!,
        powerOutput: mapValueOfType<int>(json, r'powerOutput')!,
        requirements: ShipRequirements.fromJson(json[r'requirements'])!,
      );
    }
    return null;
  }

  static List<ShipReactor> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipReactor>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipReactor.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipReactor> mapFromJson(dynamic json) {
    final map = <String, ShipReactor>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipReactor.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipReactor-objects as value to a dart map
  static Map<String, List<ShipReactor>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipReactor>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipReactor.listFromJson(
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
    'condition',
    'integrity',
    'powerOutput',
    'requirements',
  };
}

/// Symbol of the reactor.
class ShipReactorSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipReactorSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SOLAR_I = ShipReactorSymbolEnum._(r'REACTOR_SOLAR_I');
  static const FUSION_I = ShipReactorSymbolEnum._(r'REACTOR_FUSION_I');
  static const FISSION_I = ShipReactorSymbolEnum._(r'REACTOR_FISSION_I');
  static const CHEMICAL_I = ShipReactorSymbolEnum._(r'REACTOR_CHEMICAL_I');
  static const ANTIMATTER_I = ShipReactorSymbolEnum._(r'REACTOR_ANTIMATTER_I');

  /// List of all possible values in this [enum][ShipReactorSymbolEnum].
  static const values = <ShipReactorSymbolEnum>[
    SOLAR_I,
    FUSION_I,
    FISSION_I,
    CHEMICAL_I,
    ANTIMATTER_I,
  ];

  static ShipReactorSymbolEnum? fromJson(dynamic value) =>
      ShipReactorSymbolEnumTypeTransformer().decode(value);

  static List<ShipReactorSymbolEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipReactorSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipReactorSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipReactorSymbolEnum] to String,
/// and [decode] dynamic data back to [ShipReactorSymbolEnum].
class ShipReactorSymbolEnumTypeTransformer {
  factory ShipReactorSymbolEnumTypeTransformer() =>
      _instance ??= const ShipReactorSymbolEnumTypeTransformer._();

  const ShipReactorSymbolEnumTypeTransformer._();

  String encode(ShipReactorSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipReactorSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipReactorSymbolEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'REACTOR_SOLAR_I':
          return ShipReactorSymbolEnum.SOLAR_I;
        case r'REACTOR_FUSION_I':
          return ShipReactorSymbolEnum.FUSION_I;
        case r'REACTOR_FISSION_I':
          return ShipReactorSymbolEnum.FISSION_I;
        case r'REACTOR_CHEMICAL_I':
          return ShipReactorSymbolEnum.CHEMICAL_I;
        case r'REACTOR_ANTIMATTER_I':
          return ShipReactorSymbolEnum.ANTIMATTER_I;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipReactorSymbolEnumTypeTransformer] instance.
  static ShipReactorSymbolEnumTypeTransformer? _instance;
}
