//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class TransferCargo200ResponseData {
  /// Returns a new [TransferCargo200ResponseData] instance.
  TransferCargo200ResponseData({
    required this.cargo,
    required this.targetCargo,
  });

  ShipCargo cargo;

  ShipCargo targetCargo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferCargo200ResponseData &&
          other.cargo == cargo &&
          other.targetCargo == targetCargo;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cargo.hashCode) + (targetCargo.hashCode);

  @override
  String toString() =>
      'TransferCargo200ResponseData[cargo=$cargo, targetCargo=$targetCargo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cargo'] = this.cargo;
    json[r'targetCargo'] = this.targetCargo;
    return json;
  }

  /// Returns a new [TransferCargo200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TransferCargo200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "TransferCargo200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "TransferCargo200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TransferCargo200ResponseData(
        cargo: ShipCargo.fromJson(json[r'cargo'])!,
        targetCargo: ShipCargo.fromJson(json[r'targetCargo'])!,
      );
    }
    return null;
  }

  static List<TransferCargo200ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TransferCargo200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TransferCargo200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TransferCargo200ResponseData> mapFromJson(dynamic json) {
    final map = <String, TransferCargo200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TransferCargo200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TransferCargo200ResponseData-objects as value to a dart map
  static Map<String, List<TransferCargo200ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TransferCargo200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TransferCargo200ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cargo',
    'targetCargo',
  };
}
