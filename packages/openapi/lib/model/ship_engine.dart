//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipEngine {
  /// Returns a new [ShipEngine] instance.
  ShipEngine({
    required this.symbol,
    required this.name,
    required this.description,
    required this.condition,
    required this.integrity,
    required this.speed,
    required this.requirements,
  });

  /// The symbol of the engine.
  ShipEngineSymbolEnum symbol;

  /// The name of the engine.
  String name;

  /// The description of the engine.
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

  /// The speed stat of this engine. The higher the speed, the faster a ship can travel from one point to another. Reduces the time of arrival when navigating the ship.
  ///
  /// Minimum value: 1
  int speed;

  ShipRequirements requirements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipEngine &&
          other.symbol == symbol &&
          other.name == name &&
          other.description == description &&
          other.condition == condition &&
          other.integrity == integrity &&
          other.speed == speed &&
          other.requirements == requirements;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (name.hashCode) +
      (description.hashCode) +
      (condition.hashCode) +
      (integrity.hashCode) +
      (speed.hashCode) +
      (requirements.hashCode);

  @override
  String toString() =>
      'ShipEngine[symbol=$symbol, name=$name, description=$description, condition=$condition, integrity=$integrity, speed=$speed, requirements=$requirements]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'name'] = this.name;
    json[r'description'] = this.description;
    json[r'condition'] = this.condition;
    json[r'integrity'] = this.integrity;
    json[r'speed'] = this.speed;
    json[r'requirements'] = this.requirements;
    return json;
  }

  /// Returns a new [ShipEngine] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipEngine? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipEngine[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipEngine[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipEngine(
        symbol: ShipEngineSymbolEnum.fromJson(json[r'symbol'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        condition: mapValueOfType<double>(json, r'condition')!,
        integrity: mapValueOfType<double>(json, r'integrity')!,
        speed: mapValueOfType<int>(json, r'speed')!,
        requirements: ShipRequirements.fromJson(json[r'requirements'])!,
      );
    }
    return null;
  }

  static List<ShipEngine> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipEngine>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipEngine.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipEngine> mapFromJson(dynamic json) {
    final map = <String, ShipEngine>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipEngine.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipEngine-objects as value to a dart map
  static Map<String, List<ShipEngine>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipEngine>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipEngine.listFromJson(
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
    'speed',
    'requirements',
  };
}

/// The symbol of the engine.
class ShipEngineSymbolEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipEngineSymbolEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const IMPULSE_DRIVE_I =
      ShipEngineSymbolEnum._(r'ENGINE_IMPULSE_DRIVE_I');
  static const ION_DRIVE_I = ShipEngineSymbolEnum._(r'ENGINE_ION_DRIVE_I');
  static const ION_DRIVE_II = ShipEngineSymbolEnum._(r'ENGINE_ION_DRIVE_II');
  static const HYPER_DRIVE_I = ShipEngineSymbolEnum._(r'ENGINE_HYPER_DRIVE_I');

  /// List of all possible values in this [enum][ShipEngineSymbolEnum].
  static const values = <ShipEngineSymbolEnum>[
    IMPULSE_DRIVE_I,
    ION_DRIVE_I,
    ION_DRIVE_II,
    HYPER_DRIVE_I,
  ];

  static ShipEngineSymbolEnum? fromJson(dynamic value) =>
      ShipEngineSymbolEnumTypeTransformer().decode(value);

  static List<ShipEngineSymbolEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipEngineSymbolEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipEngineSymbolEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipEngineSymbolEnum] to String,
/// and [decode] dynamic data back to [ShipEngineSymbolEnum].
class ShipEngineSymbolEnumTypeTransformer {
  factory ShipEngineSymbolEnumTypeTransformer() =>
      _instance ??= const ShipEngineSymbolEnumTypeTransformer._();

  const ShipEngineSymbolEnumTypeTransformer._();

  String encode(ShipEngineSymbolEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipEngineSymbolEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipEngineSymbolEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ENGINE_IMPULSE_DRIVE_I':
          return ShipEngineSymbolEnum.IMPULSE_DRIVE_I;
        case r'ENGINE_ION_DRIVE_I':
          return ShipEngineSymbolEnum.ION_DRIVE_I;
        case r'ENGINE_ION_DRIVE_II':
          return ShipEngineSymbolEnum.ION_DRIVE_II;
        case r'ENGINE_HYPER_DRIVE_I':
          return ShipEngineSymbolEnum.HYPER_DRIVE_I;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipEngineSymbolEnumTypeTransformer] instance.
  static ShipEngineSymbolEnumTypeTransformer? _instance;
}
