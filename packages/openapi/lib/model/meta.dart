//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Meta {
  /// Returns a new [Meta] instance.
  Meta({
    required this.total,
    this.page = 1,
    this.limit = 10,
  });

  /// Shows the total amount of items of this kind that exist.
  ///
  /// Minimum value: 0
  int total;

  /// A page denotes an amount of items, offset from the first item. Each page holds an amount of items equal to the `limit`.
  ///
  /// Minimum value: 1
  int page;

  /// The amount of items in each page. Limits how many items can be fetched at once.
  ///
  /// Minimum value: 1
  /// Maximum value: 20
  int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meta &&
          other.total == total &&
          other.page == page &&
          other.limit == limit;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (total.hashCode) + (page.hashCode) + (limit.hashCode);

  @override
  String toString() => 'Meta[total=$total, page=$page, limit=$limit]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'total'] = this.total;
    json[r'page'] = this.page;
    json[r'limit'] = this.limit;
    return json;
  }

  /// Returns a new [Meta] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Meta? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Meta[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Meta[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Meta(
        total: mapValueOfType<int>(json, r'total')!,
        page: mapValueOfType<int>(json, r'page')!,
        limit: mapValueOfType<int>(json, r'limit')!,
      );
    }
    return null;
  }

  static List<Meta> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Meta>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Meta.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Meta> mapFromJson(dynamic json) {
    final map = <String, Meta>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Meta.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Meta-objects as value to a dart map
  static Map<String, List<Meta>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Meta>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Meta.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'total',
    'page',
    'limit',
  };
}
