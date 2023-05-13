//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class JumpGate {
  /// Returns a new [JumpGate] instance.
  JumpGate({
    required this.jumpRange,
    this.factionSymbol,
    this.connectedSystems = const [],
  });

  /// The maximum jump range of the gate.
  num jumpRange;

  /// The symbol of the faction that owns the gate.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? factionSymbol;

  /// The systems within range of the gate that have a corresponding gate.
  List<ConnectedSystem> connectedSystems;

  @override
  bool operator ==(Object other) => identical(this, other) || other is JumpGate &&
     other.jumpRange == jumpRange &&
     other.factionSymbol == factionSymbol &&
     other.connectedSystems == connectedSystems;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (jumpRange.hashCode) +
    (factionSymbol == null ? 0 : factionSymbol!.hashCode) +
    (connectedSystems.hashCode);

  @override
  String toString() => 'JumpGate[jumpRange=$jumpRange, factionSymbol=$factionSymbol, connectedSystems=$connectedSystems]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'jumpRange'] = this.jumpRange;
    if (this.factionSymbol != null) {
      json[r'factionSymbol'] = this.factionSymbol;
    } else {
      json[r'factionSymbol'] = null;
    }
      json[r'connectedSystems'] = this.connectedSystems;
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
          assert(json.containsKey(key), 'Required key "JumpGate[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "JumpGate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return JumpGate(
        jumpRange: num.parse(json[r'jumpRange'].toString()),
        factionSymbol: mapValueOfType<String>(json, r'factionSymbol'),
        connectedSystems: ConnectedSystem.listFromJson(json[r'connectedSystems'])!,
      );
    }
    return null;
  }

  static List<JumpGate>? listFromJson(dynamic json, {bool growable = false,}) {
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
  static Map<String, List<JumpGate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<JumpGate>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = JumpGate.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'jumpRange',
    'connectedSystems',
  };
}

