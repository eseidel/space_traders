//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class RemoveMount201ResponseData {
  /// Returns a new [RemoveMount201ResponseData] instance.
  RemoveMount201ResponseData({
    required this.agent,
    this.mounts = const [],
    required this.cargo,
    required this.transaction,
  });

  Agent agent;

  /// List of installed mounts after the removal of the selected mount.
  List<ShipMount> mounts;

  ShipCargo cargo;

  ShipModificationTransaction transaction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoveMount201ResponseData &&
          other.agent == agent &&
          _deepEquality.equals(other.mounts, mounts) &&
          other.cargo == cargo &&
          other.transaction == transaction;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (agent.hashCode) +
      (mounts.hashCode) +
      (cargo.hashCode) +
      (transaction.hashCode);

  @override
  String toString() =>
      'RemoveMount201ResponseData[agent=$agent, mounts=$mounts, cargo=$cargo, transaction=$transaction]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'agent'] = this.agent;
    json[r'mounts'] = this.mounts;
    json[r'cargo'] = this.cargo;
    json[r'transaction'] = this.transaction;
    return json;
  }

  /// Returns a new [RemoveMount201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RemoveMount201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "RemoveMount201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "RemoveMount201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RemoveMount201ResponseData(
        agent: Agent.fromJson(json[r'agent'])!,
        mounts: ShipMount.listFromJson(json[r'mounts']),
        cargo: ShipCargo.fromJson(json[r'cargo'])!,
        transaction:
            ShipModificationTransaction.fromJson(json[r'transaction'])!,
      );
    }
    return null;
  }

  static List<RemoveMount201ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RemoveMount201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RemoveMount201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RemoveMount201ResponseData> mapFromJson(dynamic json) {
    final map = <String, RemoveMount201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RemoveMount201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RemoveMount201ResponseData-objects as value to a dart map
  static Map<String, List<RemoveMount201ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RemoveMount201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RemoveMount201ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'agent',
    'mounts',
    'cargo',
    'transaction',
  };
}
