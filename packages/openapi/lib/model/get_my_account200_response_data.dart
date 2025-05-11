//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetMyAccount200ResponseData {
  /// Returns a new [GetMyAccount200ResponseData] instance.
  GetMyAccount200ResponseData({
    required this.account,
  });

  GetMyAccount200ResponseDataAccount account;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetMyAccount200ResponseData && other.account == account;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (account.hashCode);

  @override
  String toString() => 'GetMyAccount200ResponseData[account=$account]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'account'] = this.account;
    return json;
  }

  /// Returns a new [GetMyAccount200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetMyAccount200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetMyAccount200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetMyAccount200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetMyAccount200ResponseData(
        account: GetMyAccount200ResponseDataAccount.fromJson(json[r'account'])!,
      );
    }
    return null;
  }

  static List<GetMyAccount200ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetMyAccount200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetMyAccount200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetMyAccount200ResponseData> mapFromJson(dynamic json) {
    final map = <String, GetMyAccount200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetMyAccount200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetMyAccount200ResponseData-objects as value to a dart map
  static Map<String, List<GetMyAccount200ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetMyAccount200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetMyAccount200ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'account',
  };
}
