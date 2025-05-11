//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetMyAccount200ResponseDataAccount {
  /// Returns a new [GetMyAccount200ResponseDataAccount] instance.
  GetMyAccount200ResponseDataAccount({
    required this.id,
    required this.email,
    this.token,
    required this.createdAt,
  });

  String id;

  String? email;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? token;

  DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetMyAccount200ResponseDataAccount &&
          other.id == id &&
          other.email == email &&
          other.token == token &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (email == null ? 0 : email!.hashCode) +
      (token == null ? 0 : token!.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'GetMyAccount200ResponseDataAccount[id=$id, email=$email, token=$token, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.token != null) {
      json[r'token'] = this.token;
    } else {
      json[r'token'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [GetMyAccount200ResponseDataAccount] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetMyAccount200ResponseDataAccount? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetMyAccount200ResponseDataAccount[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetMyAccount200ResponseDataAccount[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetMyAccount200ResponseDataAccount(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email'),
        token: mapValueOfType<String>(json, r'token'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<GetMyAccount200ResponseDataAccount> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetMyAccount200ResponseDataAccount>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetMyAccount200ResponseDataAccount.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetMyAccount200ResponseDataAccount> mapFromJson(
      dynamic json) {
    final map = <String, GetMyAccount200ResponseDataAccount>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetMyAccount200ResponseDataAccount.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetMyAccount200ResponseDataAccount-objects as value to a dart map
  static Map<String, List<GetMyAccount200ResponseDataAccount>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetMyAccount200ResponseDataAccount>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetMyAccount200ResponseDataAccount.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'email',
    'createdAt',
  };
}
