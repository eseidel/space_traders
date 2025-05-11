//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class AgentEvent {
  /// Returns a new [AgentEvent] instance.
  AgentEvent({
    required this.id,
    required this.type,
    required this.message,
    this.data,
    required this.createdAt,
  });

  String id;

  String type;

  String message;

  Object? data;

  DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentEvent &&
          other.id == id &&
          other.type == type &&
          other.message == message &&
          other.data == data &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (type.hashCode) +
      (message.hashCode) +
      (data == null ? 0 : data!.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'AgentEvent[id=$id, type=$type, message=$message, data=$data, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'type'] = this.type;
    json[r'message'] = this.message;
    if (this.data != null) {
      json[r'data'] = this.data;
    } else {
      json[r'data'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [AgentEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AgentEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AgentEvent[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AgentEvent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AgentEvent(
        id: mapValueOfType<String>(json, r'id')!,
        type: mapValueOfType<String>(json, r'type')!,
        message: mapValueOfType<String>(json, r'message')!,
        data: mapValueOfType<Object>(json, r'data'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<AgentEvent> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AgentEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AgentEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AgentEvent> mapFromJson(dynamic json) {
    final map = <String, AgentEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AgentEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AgentEvent-objects as value to a dart map
  static Map<String, List<AgentEvent>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AgentEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AgentEvent.listFromJson(
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
    'type',
    'message',
    'createdAt',
  };
}
