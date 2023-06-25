//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipRefineRequest {
  /// Returns a new [ShipRefineRequest] instance.
  ShipRefineRequest({
    required this.produce,
  });

  /// The type of good to produce out of the refining process.
  ShipRefineRequestProduceEnum produce;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipRefineRequest && other.produce == produce;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (produce.hashCode);

  @override
  String toString() => 'ShipRefineRequest[produce=$produce]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'produce'] = this.produce;
    return json;
  }

  /// Returns a new [ShipRefineRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipRefineRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipRefineRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipRefineRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipRefineRequest(
        produce: ShipRefineRequestProduceEnum.fromJson(json[r'produce'])!,
      );
    }
    return null;
  }

  static List<ShipRefineRequest>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipRefineRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipRefineRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipRefineRequest> mapFromJson(dynamic json) {
    final map = <String, ShipRefineRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipRefineRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipRefineRequest-objects as value to a dart map
  static Map<String, List<ShipRefineRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipRefineRequest>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipRefineRequest.listFromJson(
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
    'produce',
  };
}

/// The type of good to produce out of the refining process.
class ShipRefineRequestProduceEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipRefineRequestProduceEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const IRON = ShipRefineRequestProduceEnum._(r'IRON');
  static const COPPER = ShipRefineRequestProduceEnum._(r'COPPER');
  static const SILVER = ShipRefineRequestProduceEnum._(r'SILVER');
  static const GOLD = ShipRefineRequestProduceEnum._(r'GOLD');
  static const ALUMINUM = ShipRefineRequestProduceEnum._(r'ALUMINUM');
  static const PLATINUM = ShipRefineRequestProduceEnum._(r'PLATINUM');
  static const URANITE = ShipRefineRequestProduceEnum._(r'URANITE');
  static const MERITIUM = ShipRefineRequestProduceEnum._(r'MERITIUM');
  static const FUEL = ShipRefineRequestProduceEnum._(r'FUEL');

  /// List of all possible values in this [enum][ShipRefineRequestProduceEnum].
  static const values = <ShipRefineRequestProduceEnum>[
    IRON,
    COPPER,
    SILVER,
    GOLD,
    ALUMINUM,
    PLATINUM,
    URANITE,
    MERITIUM,
    FUEL,
  ];

  static ShipRefineRequestProduceEnum? fromJson(dynamic value) =>
      ShipRefineRequestProduceEnumTypeTransformer().decode(value);

  static List<ShipRefineRequestProduceEnum>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipRefineRequestProduceEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipRefineRequestProduceEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipRefineRequestProduceEnum] to String,
/// and [decode] dynamic data back to [ShipRefineRequestProduceEnum].
class ShipRefineRequestProduceEnumTypeTransformer {
  factory ShipRefineRequestProduceEnumTypeTransformer() =>
      _instance ??= const ShipRefineRequestProduceEnumTypeTransformer._();

  const ShipRefineRequestProduceEnumTypeTransformer._();

  String encode(ShipRefineRequestProduceEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipRefineRequestProduceEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipRefineRequestProduceEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'IRON':
          return ShipRefineRequestProduceEnum.IRON;
        case r'COPPER':
          return ShipRefineRequestProduceEnum.COPPER;
        case r'SILVER':
          return ShipRefineRequestProduceEnum.SILVER;
        case r'GOLD':
          return ShipRefineRequestProduceEnum.GOLD;
        case r'ALUMINUM':
          return ShipRefineRequestProduceEnum.ALUMINUM;
        case r'PLATINUM':
          return ShipRefineRequestProduceEnum.PLATINUM;
        case r'URANITE':
          return ShipRefineRequestProduceEnum.URANITE;
        case r'MERITIUM':
          return ShipRefineRequestProduceEnum.MERITIUM;
        case r'FUEL':
          return ShipRefineRequestProduceEnum.FUEL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipRefineRequestProduceEnumTypeTransformer] instance.
  static ShipRefineRequestProduceEnumTypeTransformer? _instance;
}
