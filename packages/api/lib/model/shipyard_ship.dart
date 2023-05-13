//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ShipyardShip {
  /// Returns a new [ShipyardShip] instance.
  ShipyardShip({
    this.type,
    required this.name,
    required this.description,
    required this.purchasePrice,
    required this.frame,
    required this.reactor,
    required this.engine,
    this.modules = const [],
    this.mounts = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ShipType? type;

  String name;

  String description;

  int purchasePrice;

  ShipFrame frame;

  ShipReactor reactor;

  ShipEngine engine;

  List<ShipModule> modules;

  List<ShipMount> mounts;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ShipyardShip &&
     other.type == type &&
     other.name == name &&
     other.description == description &&
     other.purchasePrice == purchasePrice &&
     other.frame == frame &&
     other.reactor == reactor &&
     other.engine == engine &&
     other.modules == modules &&
     other.mounts == mounts;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type == null ? 0 : type!.hashCode) +
    (name.hashCode) +
    (description.hashCode) +
    (purchasePrice.hashCode) +
    (frame.hashCode) +
    (reactor.hashCode) +
    (engine.hashCode) +
    (modules.hashCode) +
    (mounts.hashCode);

  @override
  String toString() => 'ShipyardShip[type=$type, name=$name, description=$description, purchasePrice=$purchasePrice, frame=$frame, reactor=$reactor, engine=$engine, modules=$modules, mounts=$mounts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'purchasePrice'] = this.purchasePrice;
      json[r'frame'] = this.frame;
      json[r'reactor'] = this.reactor;
      json[r'engine'] = this.engine;
      json[r'modules'] = this.modules;
      json[r'mounts'] = this.mounts;
    return json;
  }

  /// Returns a new [ShipyardShip] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipyardShip? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ShipyardShip[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ShipyardShip[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipyardShip(
        type: ShipType.fromJson(json[r'type']),
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        purchasePrice: mapValueOfType<int>(json, r'purchasePrice')!,
        frame: ShipFrame.fromJson(json[r'frame'])!,
        reactor: ShipReactor.fromJson(json[r'reactor'])!,
        engine: ShipEngine.fromJson(json[r'engine'])!,
        modules: ShipModule.listFromJson(json[r'modules'])!,
        mounts: ShipMount.listFromJson(json[r'mounts'])!,
      );
    }
    return null;
  }

  static List<ShipyardShip>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ShipyardShip>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipyardShip.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipyardShip> mapFromJson(dynamic json) {
    final map = <String, ShipyardShip>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipyardShip.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipyardShip-objects as value to a dart map
  static Map<String, List<ShipyardShip>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ShipyardShip>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipyardShip.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'description',
    'purchasePrice',
    'frame',
    'reactor',
    'engine',
    'modules',
    'mounts',
  };
}

