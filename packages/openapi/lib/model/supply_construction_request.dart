//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class SupplyConstructionRequest {
  /// Returns a new [SupplyConstructionRequest] instance.
  SupplyConstructionRequest({
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.units,
  });

  /// The symbol of the ship supplying construction materials.
  String shipSymbol;

  /// The symbol of the good to supply.
  TradeSymbol tradeSymbol;

  /// Amount of units to supply.
  ///
  /// Minimum value: 1
  int units;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplyConstructionRequest &&
          other.shipSymbol == shipSymbol &&
          other.tradeSymbol == tradeSymbol &&
          other.units == units;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (shipSymbol.hashCode) + (tradeSymbol.hashCode) + (units.hashCode);

  @override
  String toString() =>
      'SupplyConstructionRequest[shipSymbol=$shipSymbol, tradeSymbol=$tradeSymbol, units=$units]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'tradeSymbol'] = this.tradeSymbol;
    json[r'units'] = this.units;
    return json;
  }

  /// Returns a new [SupplyConstructionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SupplyConstructionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SupplyConstructionRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SupplyConstructionRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SupplyConstructionRequest(
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        tradeSymbol: TradeSymbol.fromJson(json[r'tradeSymbol'])!,
        units: mapValueOfType<int>(json, r'units')!,
      );
    }
    return null;
  }

  static List<SupplyConstructionRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SupplyConstructionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SupplyConstructionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SupplyConstructionRequest> mapFromJson(dynamic json) {
    final map = <String, SupplyConstructionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SupplyConstructionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SupplyConstructionRequest-objects as value to a dart map
  static Map<String, List<SupplyConstructionRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SupplyConstructionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SupplyConstructionRequest.listFromJson(
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
