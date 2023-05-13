//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ContractDeliverGood {
  /// Returns a new [ContractDeliverGood] instance.
  ContractDeliverGood({
    required this.tradeSymbol,
    required this.destinationSymbol,
    required this.unitsRequired,
    required this.unitsFulfilled,
  });

  /// The symbol of the trade good to deliver.
  String tradeSymbol;

  /// The destination where goods need to be delivered.
  String destinationSymbol;

  /// The number of units that need to be delivered on this contract.
  int unitsRequired;

  /// The number of units fulfilled on this contract.
  int unitsFulfilled;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ContractDeliverGood &&
     other.tradeSymbol == tradeSymbol &&
     other.destinationSymbol == destinationSymbol &&
     other.unitsRequired == unitsRequired &&
     other.unitsFulfilled == unitsFulfilled;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (tradeSymbol.hashCode) +
    (destinationSymbol.hashCode) +
    (unitsRequired.hashCode) +
    (unitsFulfilled.hashCode);

  @override
  String toString() => 'ContractDeliverGood[tradeSymbol=$tradeSymbol, destinationSymbol=$destinationSymbol, unitsRequired=$unitsRequired, unitsFulfilled=$unitsFulfilled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'tradeSymbol'] = this.tradeSymbol;
      json[r'destinationSymbol'] = this.destinationSymbol;
      json[r'unitsRequired'] = this.unitsRequired;
      json[r'unitsFulfilled'] = this.unitsFulfilled;
    return json;
  }

  /// Returns a new [ContractDeliverGood] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContractDeliverGood? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ContractDeliverGood[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ContractDeliverGood[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContractDeliverGood(
        tradeSymbol: mapValueOfType<String>(json, r'tradeSymbol')!,
        destinationSymbol: mapValueOfType<String>(json, r'destinationSymbol')!,
        unitsRequired: mapValueOfType<int>(json, r'unitsRequired')!,
        unitsFulfilled: mapValueOfType<int>(json, r'unitsFulfilled')!,
      );
    }
    return null;
  }

  static List<ContractDeliverGood>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ContractDeliverGood>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContractDeliverGood.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContractDeliverGood> mapFromJson(dynamic json) {
    final map = <String, ContractDeliverGood>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractDeliverGood.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContractDeliverGood-objects as value to a dart map
  static Map<String, List<ContractDeliverGood>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ContractDeliverGood>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContractDeliverGood.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'tradeSymbol',
    'destinationSymbol',
    'unitsRequired',
    'unitsFulfilled',
  };
}

