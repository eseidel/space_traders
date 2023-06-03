//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class InstallMount201ResponseDataTransaction {
  /// Returns a new [InstallMount201ResponseDataTransaction] instance.
  InstallMount201ResponseDataTransaction({
    required this.totalPrice,
    required this.timestamp,
  });

  /// The total price of the transaction.
  ///
  /// Minimum value: 0
  int totalPrice;

  /// The timestamp of the transaction.
  DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallMount201ResponseDataTransaction &&
          other.totalPrice == totalPrice &&
          other.timestamp == timestamp;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (totalPrice.hashCode) + (timestamp.hashCode);

  @override
  String toString() =>
      'InstallMount201ResponseDataTransaction[totalPrice=$totalPrice, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'totalPrice'] = this.totalPrice;
    json[r'timestamp'] = this.timestamp.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [InstallMount201ResponseDataTransaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InstallMount201ResponseDataTransaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "InstallMount201ResponseDataTransaction[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "InstallMount201ResponseDataTransaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InstallMount201ResponseDataTransaction(
        totalPrice: mapValueOfType<int>(json, r'totalPrice')!,
        timestamp: mapDateTime(json, r'timestamp', '')!,
      );
    }
    return null;
  }

  static List<InstallMount201ResponseDataTransaction>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <InstallMount201ResponseDataTransaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InstallMount201ResponseDataTransaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InstallMount201ResponseDataTransaction> mapFromJson(
      dynamic json) {
    final map = <String, InstallMount201ResponseDataTransaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            InstallMount201ResponseDataTransaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InstallMount201ResponseDataTransaction-objects as value to a dart map
  static Map<String, List<InstallMount201ResponseDataTransaction>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<InstallMount201ResponseDataTransaction>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InstallMount201ResponseDataTransaction.listFromJson(
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
    'totalPrice',
    'timestamp',
  };
}
