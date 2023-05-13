//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class RegisterRequest {
  /// Returns a new [RegisterRequest] instance.
  RegisterRequest({
    required this.faction,
    required this.symbol,
  });

  /// The faction you choose determines your headquarters.
  RegisterRequestFactionEnum faction;

  /// How other agents will see your ships and information.
  String symbol;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequest &&
     other.faction == faction &&
     other.symbol == symbol;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (faction.hashCode) +
    (symbol.hashCode);

  @override
  String toString() => 'RegisterRequest[faction=$faction, symbol=$symbol]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'faction'] = this.faction;
      json[r'symbol'] = this.symbol;
    return json;
  }

  /// Returns a new [RegisterRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RegisterRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RegisterRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RegisterRequest(
        faction: RegisterRequestFactionEnum.fromJson(json[r'faction'])!,
        symbol: mapValueOfType<String>(json, r'symbol')!,
      );
    }
    return null;
  }

  static List<RegisterRequest>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequest> mapFromJson(dynamic json) {
    final map = <String, RegisterRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequest-objects as value to a dart map
  static Map<String, List<RegisterRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequest>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequest.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'faction',
    'symbol',
  };
}

/// The faction you choose determines your headquarters.
class RegisterRequestFactionEnum {
  /// Instantiate a new enum with the provided [value].
  const RegisterRequestFactionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const COSMIC = RegisterRequestFactionEnum._(r'COSMIC');
  static const VOID = RegisterRequestFactionEnum._(r'VOID');
  static const GALACTIC = RegisterRequestFactionEnum._(r'GALACTIC');
  static const QUANTUM = RegisterRequestFactionEnum._(r'QUANTUM');
  static const DOMINION = RegisterRequestFactionEnum._(r'DOMINION');

  /// List of all possible values in this [enum][RegisterRequestFactionEnum].
  static const values = <RegisterRequestFactionEnum>[
    COSMIC,
    VOID,
    GALACTIC,
    QUANTUM,
    DOMINION,
  ];

  static RegisterRequestFactionEnum? fromJson(dynamic value) => RegisterRequestFactionEnumTypeTransformer().decode(value);

  static List<RegisterRequestFactionEnum>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequestFactionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequestFactionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterRequestFactionEnum] to String,
/// and [decode] dynamic data back to [RegisterRequestFactionEnum].
class RegisterRequestFactionEnumTypeTransformer {
  factory RegisterRequestFactionEnumTypeTransformer() => _instance ??= const RegisterRequestFactionEnumTypeTransformer._();

  const RegisterRequestFactionEnumTypeTransformer._();

  String encode(RegisterRequestFactionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a RegisterRequestFactionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterRequestFactionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'COSMIC': return RegisterRequestFactionEnum.COSMIC;
        case r'VOID': return RegisterRequestFactionEnum.VOID;
        case r'GALACTIC': return RegisterRequestFactionEnum.GALACTIC;
        case r'QUANTUM': return RegisterRequestFactionEnum.QUANTUM;
        case r'DOMINION': return RegisterRequestFactionEnum.DOMINION;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RegisterRequestFactionEnumTypeTransformer] instance.
  static RegisterRequestFactionEnumTypeTransformer? _instance;
}


