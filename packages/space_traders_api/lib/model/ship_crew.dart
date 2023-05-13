//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ShipCrew {
  /// Returns a new [ShipCrew] instance.
  ShipCrew({
    required this.current,
    required this.required_,
    required this.capacity,
    this.rotation = const ShipCrewRotationEnum._('STRICT'),
    required this.morale,
    required this.wages,
  });

  /// The current number of crew members on the ship.
  int current;

  /// The minimum number of crew members required to maintain the ship.
  int required_;

  /// The maximum number of crew members the ship can support.
  int capacity;

  /// The rotation of crew shifts. A stricter shift improves the ship's performance. A more relaxed shift improves the crew's morale.
  ShipCrewRotationEnum rotation;

  /// A rough measure of the crew's morale. A higher morale means the crew is happier and more productive. A lower morale means the ship is more prone to accidents.
  ///
  /// Minimum value: 0
  /// Maximum value: 100
  int morale;

  /// The amount of credits per crew member paid per hour. Wages are paid when a ship docks at a civilized waypoint.
  ///
  /// Minimum value: 0
  int wages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipCrew &&
          other.current == current &&
          other.required_ == required_ &&
          other.capacity == capacity &&
          other.rotation == rotation &&
          other.morale == morale &&
          other.wages == wages;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (current.hashCode) +
      (required_.hashCode) +
      (capacity.hashCode) +
      (rotation.hashCode) +
      (morale.hashCode) +
      (wages.hashCode);

  @override
  String toString() =>
      'ShipCrew[current=$current, required_=$required_, capacity=$capacity, rotation=$rotation, morale=$morale, wages=$wages]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'current'] = this.current;
    json[r'required'] = this.required_;
    json[r'capacity'] = this.capacity;
    json[r'rotation'] = this.rotation;
    json[r'morale'] = this.morale;
    json[r'wages'] = this.wages;
    return json;
  }

  /// Returns a new [ShipCrew] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipCrew? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipCrew[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipCrew[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipCrew(
        current: mapValueOfType<int>(json, r'current')!,
        required_: mapValueOfType<int>(json, r'required')!,
        capacity: mapValueOfType<int>(json, r'capacity')!,
        rotation: ShipCrewRotationEnum.fromJson(json[r'rotation'])!,
        morale: mapValueOfType<int>(json, r'morale')!,
        wages: mapValueOfType<int>(json, r'wages')!,
      );
    }
    return null;
  }

  static List<ShipCrew>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipCrew>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipCrew.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipCrew> mapFromJson(dynamic json) {
    final map = <String, ShipCrew>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipCrew.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipCrew-objects as value to a dart map
  static Map<String, List<ShipCrew>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipCrew>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipCrew.listFromJson(
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
    'current',
    'required',
    'capacity',
    'rotation',
    'morale',
    'wages',
  };
}

/// The rotation of crew shifts. A stricter shift improves the ship's performance. A more relaxed shift improves the crew's morale.
class ShipCrewRotationEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipCrewRotationEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const STRICT = ShipCrewRotationEnum._(r'STRICT');
  static const RELAXED = ShipCrewRotationEnum._(r'RELAXED');

  /// List of all possible values in this [enum][ShipCrewRotationEnum].
  static const values = <ShipCrewRotationEnum>[
    STRICT,
    RELAXED,
  ];

  static ShipCrewRotationEnum? fromJson(dynamic value) =>
      ShipCrewRotationEnumTypeTransformer().decode(value);

  static List<ShipCrewRotationEnum>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipCrewRotationEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipCrewRotationEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipCrewRotationEnum] to String,
/// and [decode] dynamic data back to [ShipCrewRotationEnum].
class ShipCrewRotationEnumTypeTransformer {
  factory ShipCrewRotationEnumTypeTransformer() =>
      _instance ??= const ShipCrewRotationEnumTypeTransformer._();

  const ShipCrewRotationEnumTypeTransformer._();

  String encode(ShipCrewRotationEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipCrewRotationEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipCrewRotationEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'STRICT':
          return ShipCrewRotationEnum.STRICT;
        case r'RELAXED':
          return ShipCrewRotationEnum.RELAXED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipCrewRotationEnumTypeTransformer] instance.
  static ShipCrewRotationEnumTypeTransformer? _instance;
}
