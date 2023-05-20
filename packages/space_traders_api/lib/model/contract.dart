//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class Contract {
  /// Returns a new [Contract] instance.
  Contract({
    required this.id,
    required this.factionSymbol,
    required this.type,
    required this.terms,
    this.accepted = false,
    this.fulfilled = false,
    required this.expiration,
    this.deadlineToAccept,
  });

  String id;

  /// The symbol of the faction that this contract is for.
  String factionSymbol;

  ContractTypeEnum type;

  ContractTerms terms;

  /// Whether the contract has been accepted by the agent
  bool accepted;

  /// Whether the contract has been fulfilled
  bool fulfilled;

  /// Deprecated in favor of deadlineToAccept
  DateTime expiration;

  /// The time at which the contract is no longer available to be accepted
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? deadlineToAccept;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contract &&
          other.id == id &&
          other.factionSymbol == factionSymbol &&
          other.type == type &&
          other.terms == terms &&
          other.accepted == accepted &&
          other.fulfilled == fulfilled &&
          other.expiration == expiration &&
          other.deadlineToAccept == deadlineToAccept;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (factionSymbol.hashCode) +
      (type.hashCode) +
      (terms.hashCode) +
      (accepted.hashCode) +
      (fulfilled.hashCode) +
      (expiration.hashCode) +
      (deadlineToAccept == null ? 0 : deadlineToAccept!.hashCode);

  @override
  String toString() =>
      'Contract[id=$id, factionSymbol=$factionSymbol, type=$type, terms=$terms, accepted=$accepted, fulfilled=$fulfilled, expiration=$expiration, deadlineToAccept=$deadlineToAccept]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'factionSymbol'] = this.factionSymbol;
    json[r'type'] = this.type;
    json[r'terms'] = this.terms;
    json[r'accepted'] = this.accepted;
    json[r'fulfilled'] = this.fulfilled;
    json[r'expiration'] = this.expiration.toUtc().toIso8601String();
    if (this.deadlineToAccept != null) {
      json[r'deadlineToAccept'] =
          this.deadlineToAccept!.toUtc().toIso8601String();
    } else {
      json[r'deadlineToAccept'] = null;
    }
    return json;
  }

  /// Returns a new [Contract] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Contract? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Contract[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Contract[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Contract(
        id: mapValueOfType<String>(json, r'id')!,
        factionSymbol: mapValueOfType<String>(json, r'factionSymbol')!,
        type: ContractTypeEnum.fromJson(json[r'type'])!,
        terms: ContractTerms.fromJson(json[r'terms'])!,
        accepted: mapValueOfType<bool>(json, r'accepted')!,
        fulfilled: mapValueOfType<bool>(json, r'fulfilled')!,
        expiration: mapDateTime(json, r'expiration', '')!,
        deadlineToAccept: mapDateTime(json, r'deadlineToAccept', ''),
      );
    }
    return null;
  }

  static List<Contract>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Contract>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Contract.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Contract> mapFromJson(dynamic json) {
    final map = <String, Contract>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Contract.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Contract-objects as value to a dart map
  static Map<String, List<Contract>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Contract>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Contract.listFromJson(
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
    'id',
    'factionSymbol',
    'type',
    'terms',
    'accepted',
    'fulfilled',
    'expiration',
  };
}

class ContractTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const ContractTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PROCUREMENT = ContractTypeEnum._(r'PROCUREMENT');
  static const TRANSPORT = ContractTypeEnum._(r'TRANSPORT');
  static const SHUTTLE = ContractTypeEnum._(r'SHUTTLE');

  /// List of all possible values in this [enum][ContractTypeEnum].
  static const values = <ContractTypeEnum>[
    PROCUREMENT,
    TRANSPORT,
    SHUTTLE,
  ];

  static ContractTypeEnum? fromJson(dynamic value) =>
      ContractTypeEnumTypeTransformer().decode(value);

  static List<ContractTypeEnum>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContractTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ContractTypeEnum] to String,
/// and [decode] dynamic data back to [ContractTypeEnum].
class ContractTypeEnumTypeTransformer {
  factory ContractTypeEnumTypeTransformer() =>
      _instance ??= const ContractTypeEnumTypeTransformer._();

  const ContractTypeEnumTypeTransformer._();

  String encode(ContractTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ContractTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ContractTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PROCUREMENT':
          return ContractTypeEnum.PROCUREMENT;
        case r'TRANSPORT':
          return ContractTypeEnum.TRANSPORT;
        case r'SHUTTLE':
          return ContractTypeEnum.SHUTTLE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ContractTypeEnumTypeTransformer] instance.
  static ContractTypeEnumTypeTransformer? _instance;
}
