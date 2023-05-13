//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class Cooldown {
  /// Returns a new [Cooldown] instance.
  Cooldown({
    required this.shipSymbol,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.expiration,
  });

  /// The symbol of the ship that is on cooldown
  String shipSymbol;

  /// The total duration of the cooldown in seconds
  ///
  /// Minimum value: 0
  int totalSeconds;

  /// The remaining duration of the cooldown in seconds
  ///
  /// Minimum value: 0
  int remainingSeconds;

  /// The date and time when the cooldown expires in ISO 8601 format
  DateTime expiration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cooldown &&
          other.shipSymbol == shipSymbol &&
          other.totalSeconds == totalSeconds &&
          other.remainingSeconds == remainingSeconds &&
          other.expiration == expiration;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (shipSymbol.hashCode) +
      (totalSeconds.hashCode) +
      (remainingSeconds.hashCode) +
      (expiration.hashCode);

  @override
  String toString() =>
      'Cooldown[shipSymbol=$shipSymbol, totalSeconds=$totalSeconds, remainingSeconds=$remainingSeconds, expiration=$expiration]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'totalSeconds'] = this.totalSeconds;
    json[r'remainingSeconds'] = this.remainingSeconds;
    json[r'expiration'] = this.expiration.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Cooldown] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Cooldown? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Cooldown[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Cooldown[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Cooldown(
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        totalSeconds: mapValueOfType<int>(json, r'totalSeconds')!,
        remainingSeconds: mapValueOfType<int>(json, r'remainingSeconds')!,
        expiration: mapDateTime(json, r'expiration', '')!,
      );
    }
    return null;
  }

  static List<Cooldown>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Cooldown>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Cooldown.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Cooldown> mapFromJson(dynamic json) {
    final map = <String, Cooldown>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Cooldown.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Cooldown-objects as value to a dart map
  static Map<String, List<Cooldown>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Cooldown>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Cooldown.listFromJson(
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
    'shipSymbol',
    'totalSeconds',
    'remainingSeconds',
    'expiration',
  };
}
