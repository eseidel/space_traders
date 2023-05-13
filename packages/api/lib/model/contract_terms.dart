//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ContractTerms {
  /// Returns a new [ContractTerms] instance.
  ContractTerms({
    required this.deadline,
    required this.payment,
    this.deliver = const [],
  });

  /// The deadline for the contract.
  DateTime deadline;

  ContractPayment payment;

  List<ContractDeliverGood> deliver;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ContractTerms &&
     other.deadline == deadline &&
     other.payment == payment &&
     other.deliver == deliver;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (deadline.hashCode) +
    (payment.hashCode) +
    (deliver.hashCode);

  @override
  String toString() => 'ContractTerms[deadline=$deadline, payment=$payment, deliver=$deliver]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'deadline'] = this.deadline.toUtc().toIso8601String();
      json[r'payment'] = this.payment;
      json[r'deliver'] = this.deliver;
    return json;
  }

  /// Returns a new [ContractTerms] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContractTerms? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ContractTerms[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ContractTerms[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContractTerms(
        deadline: mapDateTime(json, r'deadline', '')!,
        payment: ContractPayment.fromJson(json[r'payment'])!,
        deliver: ContractDeliverGood.listFromJson(json[r'deliver']) ?? const [],
      );
    }
    return null;
  }

  static List<ContractTerms>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ContractTerms>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractTerms.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContractTerms> mapFromJson(dynamic json) {
    final map = <String, ContractTerms>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractTerms.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContractTerms-objects as value to a dart map
  static Map<String, List<ContractTerms>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ContractTerms>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractTerms.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'deadline',
    'payment',
  };
}

