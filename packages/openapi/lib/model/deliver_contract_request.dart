//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class DeliverContractRequest {
  /// Returns a new [DeliverContractRequest] instance.
  DeliverContractRequest({
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.units,
  });

  /// Symbol of a ship located in the destination to deliver a contract and that has a good to deliver in its cargo.
  String shipSymbol;

  /// The symbol of the good to deliver.
  String tradeSymbol;

  /// Amount of units to deliver.
  ///
  /// Minimum value: 1
  int units;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliverContractRequest &&
          other.shipSymbol == shipSymbol &&
          other.tradeSymbol == tradeSymbol &&
          other.units == units;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (shipSymbol.hashCode) + (tradeSymbol.hashCode) + (units.hashCode);

  @override
  String toString() =>
      'DeliverContractRequest[shipSymbol=$shipSymbol, tradeSymbol=$tradeSymbol, units=$units]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'tradeSymbol'] = this.tradeSymbol;
    json[r'units'] = this.units;
    return json;
  }

  /// Returns a new [DeliverContractRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeliverContractRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "DeliverContractRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "DeliverContractRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DeliverContractRequest(
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        tradeSymbol: mapValueOfType<String>(json, r'tradeSymbol')!,
        units: mapValueOfType<int>(json, r'units')!,
      );
    }
    return null;
  }

  static List<DeliverContractRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DeliverContractRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeliverContractRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeliverContractRequest> mapFromJson(dynamic json) {
    final map = <String, DeliverContractRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeliverContractRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeliverContractRequest-objects as value to a dart map
  static Map<String, List<DeliverContractRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DeliverContractRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeliverContractRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'shipSymbol',
    'tradeSymbol',
    'units',
  };
}
