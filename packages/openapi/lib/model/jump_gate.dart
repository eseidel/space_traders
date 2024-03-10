//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class JumpGate {
  /// Returns a new [JumpGate] instance.
  JumpGate({
    required this.symbol,
    this.connections = const [],
  });

  /// The symbol of the waypoint.
  String symbol;

  /// All the gates that are connected to this waypoint.
  List<String> connections;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JumpGate &&
          other.symbol == symbol &&
          _deepEquality.equals(other.connections, connections);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) + (connections.hashCode);

  @override
  String toString() => 'JumpGate[symbol=$symbol, connections=$connections]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'connections'] = this.connections;
    return json;
  }

  /// Returns a new [JumpGate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static JumpGate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "JumpGate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "JumpGate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return JumpGate(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        connections: json[r'connections'] is Iterable
            ? (json[r'connections'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<JumpGate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <JumpGate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = JumpGate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, JumpGate> mapFromJson(dynamic json) {
    final map = <String, JumpGate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = JumpGate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of JumpGate-objects as value to a dart map
  static Map<String, List<JumpGate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<JumpGate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = JumpGate.listFromJson(
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
    'connections',
  };
}
