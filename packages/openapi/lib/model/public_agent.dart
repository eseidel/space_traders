//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class PublicAgent {
  /// Returns a new [PublicAgent] instance.
  PublicAgent({
    required this.symbol,
    required this.headquarters,
    required this.credits,
    required this.startingFaction,
    required this.shipCount,
  });

  /// Symbol of the agent.
  String symbol;

  /// The headquarters of the agent.
  String headquarters;

  /// The number of credits the agent has available. Credits can be negative if funds have been overdrawn.
  int credits;

  /// The faction the agent started with.
  String startingFaction;

  /// How many ships are owned by the agent.
  int shipCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicAgent &&
          other.symbol == symbol &&
          other.headquarters == headquarters &&
          other.credits == credits &&
          other.startingFaction == startingFaction &&
          other.shipCount == shipCount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (headquarters.hashCode) +
      (credits.hashCode) +
      (startingFaction.hashCode) +
      (shipCount.hashCode);

  @override
  String toString() =>
      'PublicAgent[symbol=$symbol, headquarters=$headquarters, credits=$credits, startingFaction=$startingFaction, shipCount=$shipCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'headquarters'] = this.headquarters;
    json[r'credits'] = this.credits;
    json[r'startingFaction'] = this.startingFaction;
    json[r'shipCount'] = this.shipCount;
    return json;
  }

  /// Returns a new [PublicAgent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicAgent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PublicAgent[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PublicAgent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicAgent(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        headquarters: mapValueOfType<String>(json, r'headquarters')!,
        credits: mapValueOfType<int>(json, r'credits')!,
        startingFaction: mapValueOfType<String>(json, r'startingFaction')!,
        shipCount: mapValueOfType<int>(json, r'shipCount')!,
      );
    }
    return null;
  }

  static List<PublicAgent> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PublicAgent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicAgent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicAgent> mapFromJson(dynamic json) {
    final map = <String, PublicAgent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicAgent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicAgent-objects as value to a dart map
  static Map<String, List<PublicAgent>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PublicAgent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicAgent.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
    'headquarters',
    'credits',
    'startingFaction',
    'shipCount',
  };
}
