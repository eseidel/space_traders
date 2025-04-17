//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class InstallShipModule201ResponseDataTransaction {
  /// Returns a new [InstallShipModule201ResponseDataTransaction] instance.
  InstallShipModule201ResponseDataTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.totalPrice,
    required this.timestamp,
  });

  String waypointSymbol;

  String shipSymbol;

  String tradeSymbol;

  int totalPrice;

  String timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallShipModule201ResponseDataTransaction &&
          other.waypointSymbol == waypointSymbol &&
          other.shipSymbol == shipSymbol &&
          other.tradeSymbol == tradeSymbol &&
          other.totalPrice == totalPrice &&
          other.timestamp == timestamp;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (waypointSymbol.hashCode) +
      (shipSymbol.hashCode) +
      (tradeSymbol.hashCode) +
      (totalPrice.hashCode) +
      (timestamp.hashCode);

  @override
  String toString() =>
      'InstallShipModule201ResponseDataTransaction[waypointSymbol=$waypointSymbol, shipSymbol=$shipSymbol, tradeSymbol=$tradeSymbol, totalPrice=$totalPrice, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'waypointSymbol'] = this.waypointSymbol;
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'tradeSymbol'] = this.tradeSymbol;
    json[r'totalPrice'] = this.totalPrice;
    json[r'timestamp'] = this.timestamp;
    return json;
  }

  /// Returns a new [InstallShipModule201ResponseDataTransaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InstallShipModule201ResponseDataTransaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "InstallShipModule201ResponseDataTransaction[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "InstallShipModule201ResponseDataTransaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return InstallShipModule201ResponseDataTransaction(
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        tradeSymbol: mapValueOfType<String>(json, r'tradeSymbol')!,
        totalPrice: mapValueOfType<int>(json, r'totalPrice')!,
        timestamp: mapValueOfType<String>(json, r'timestamp')!,
      );
    }
    return null;
  }

  static List<InstallShipModule201ResponseDataTransaction> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <InstallShipModule201ResponseDataTransaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InstallShipModule201ResponseDataTransaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InstallShipModule201ResponseDataTransaction> mapFromJson(
      dynamic json) {
    final map = <String, InstallShipModule201ResponseDataTransaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            InstallShipModule201ResponseDataTransaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InstallShipModule201ResponseDataTransaction-objects as value to a dart map
  static Map<String, List<InstallShipModule201ResponseDataTransaction>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<InstallShipModule201ResponseDataTransaction>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] =
            InstallShipModule201ResponseDataTransaction.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'waypointSymbol',
    'shipSymbol',
    'tradeSymbol',
    'totalPrice',
    'timestamp',
  };
}
