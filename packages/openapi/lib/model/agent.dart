//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Agent {
  /// Returns a new [Agent] instance.
  Agent({
    this.accountId,
    required this.symbol,
    required this.headquarters,
    required this.credits,
    required this.startingFaction,
    this.shipCount,
  });

  /// Account ID that is tied to this agent. Only included on your own agent.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? accountId;

  /// Symbol of the agent.
  String symbol;

  /// The headquarters of the agent.
  String headquarters;

  /// The number of credits the agent has available. Credits can be negative if funds have been overdrawn.
  int credits;

  /// The faction the agent started with.
  String startingFaction;

  /// How many ships are owned by the agent.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? shipCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Agent &&
          other.accountId == accountId &&
          other.symbol == symbol &&
          other.headquarters == headquarters &&
          other.credits == credits &&
          other.startingFaction == startingFaction &&
          other.shipCount == shipCount;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (accountId == null ? 0 : accountId!.hashCode) +
      (symbol.hashCode) +
      (headquarters.hashCode) +
      (credits.hashCode) +
      (startingFaction.hashCode) +
      (shipCount == null ? 0 : shipCount!.hashCode);

  @override
  String toString() =>
      'Agent[accountId=$accountId, symbol=$symbol, headquarters=$headquarters, credits=$credits, startingFaction=$startingFaction, shipCount=$shipCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.accountId != null) {
      json[r'accountId'] = this.accountId;
    } else {
      json[r'accountId'] = null;
    }
    json[r'symbol'] = this.symbol;
    json[r'headquarters'] = this.headquarters;
    json[r'credits'] = this.credits;
    json[r'startingFaction'] = this.startingFaction;
    if (this.shipCount != null) {
      json[r'shipCount'] = this.shipCount;
    } else {
      json[r'shipCount'] = null;
    }
    return json;
  }

  /// Returns a new [Agent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Agent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Agent[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Agent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Agent(
        accountId: mapValueOfType<String>(json, r'accountId'),
        symbol: mapValueOfType<String>(json, r'symbol')!,
        headquarters: mapValueOfType<String>(json, r'headquarters')!,
        credits: mapValueOfType<int>(json, r'credits')!,
        startingFaction: mapValueOfType<String>(json, r'startingFaction')!,
        shipCount: mapValueOfType<int>(json, r'shipCount'),
      );
    }
    return null;
  }

  static List<Agent>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Agent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Agent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Agent> mapFromJson(dynamic json) {
    final map = <String, Agent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Agent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Agent-objects as value to a dart map
  static Map<String, List<Agent>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Agent>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Agent.listFromJson(
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
    'headquarters',
    'credits',
    'startingFaction',
  };
}
