//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetSupplyChain200ResponseData {
  /// Returns a new [GetSupplyChain200ResponseData] instance.
  GetSupplyChain200ResponseData({
    this.exportToImportMap = const {},
  });

  Map<String, List<String>> exportToImportMap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSupplyChain200ResponseData &&
          _deepEquality.equals(other.exportToImportMap, exportToImportMap);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (exportToImportMap.hashCode);

  @override
  String toString() =>
      'GetSupplyChain200ResponseData[exportToImportMap=$exportToImportMap]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'exportToImportMap'] = this.exportToImportMap;
    return json;
  }

  /// Returns a new [GetSupplyChain200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetSupplyChain200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetSupplyChain200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetSupplyChain200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetSupplyChain200ResponseData(
        exportToImportMap: json[r'exportToImportMap'] == null
            ? const {}
            : mapCastOfType<String, List>(json, r'exportToImportMap'),
      );
    }
    return null;
  }

  static List<GetSupplyChain200ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetSupplyChain200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetSupplyChain200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetSupplyChain200ResponseData> mapFromJson(dynamic json) {
    final map = <String, GetSupplyChain200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetSupplyChain200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetSupplyChain200ResponseData-objects as value to a dart map
  static Map<String, List<GetSupplyChain200ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetSupplyChain200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetSupplyChain200ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'exportToImportMap',
  };
}
