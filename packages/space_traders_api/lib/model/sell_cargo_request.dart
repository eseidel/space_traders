//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class SellCargoRequest {
  /// Returns a new [SellCargoRequest] instance.
  SellCargoRequest({
    required this.symbol,
    required this.units,
  });

  TradeSymbol symbol;

  /// Amounts of units to sell of the selected good.
  int units;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellCargoRequest &&
          other.symbol == symbol &&
          other.units == units;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (units.hashCode);

  @override
  String toString() => 'SellCargoRequest[symbol=$symbol, units=$units]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'units'] = this.units;
    return json;
  }

  /// Returns a new [SellCargoRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SellCargoRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SellCargoRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SellCargoRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SellCargoRequest(
        symbol: TradeSymbol.fromJson(json[r'symbol'])!,
        units: mapValueOfType<int>(json, r'units')!,
      );
    }
    return null;
  }

  static List<SellCargoRequest>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SellCargoRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SellCargoRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SellCargoRequest> mapFromJson(dynamic json) {
    final map = <String, SellCargoRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SellCargoRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SellCargoRequest-objects as value to a dart map
  static Map<String, List<SellCargoRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SellCargoRequest>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SellCargoRequest.listFromJson(
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
    'symbol',
    'units',
  };
}
