//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ContractPayment {
  /// Returns a new [ContractPayment] instance.
  ContractPayment({
    required this.onAccepted,
    required this.onFulfilled,
  });

  /// The amount of credits received up front for accepting the contract.
  int onAccepted;

  /// The amount of credits received when the contract is fulfilled.
  int onFulfilled;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ContractPayment &&
     other.onAccepted == onAccepted &&
     other.onFulfilled == onFulfilled;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (onAccepted.hashCode) +
    (onFulfilled.hashCode);

  @override
  String toString() => 'ContractPayment[onAccepted=$onAccepted, onFulfilled=$onFulfilled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'onAccepted'] = this.onAccepted;
      json[r'onFulfilled'] = this.onFulfilled;
    return json;
  }

  /// Returns a new [ContractPayment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContractPayment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ContractPayment[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ContractPayment[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContractPayment(
        onAccepted: mapValueOfType<int>(json, r'onAccepted')!,
        onFulfilled: mapValueOfType<int>(json, r'onFulfilled')!,
      );
    }
    return null;
  }

  static List<ContractPayment>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ContractPayment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractPayment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContractPayment> mapFromJson(dynamic json) {
    final map = <String, ContractPayment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractPayment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContractPayment-objects as value to a dart map
  static Map<String, List<ContractPayment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ContractPayment>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractPayment.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'onAccepted',
    'onFulfilled',
  };
}

