//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ScannedShip {
  /// Returns a new [ScannedShip] instance.
  ScannedShip({
    required this.symbol,
    required this.registration,
    required this.nav,
    this.frame,
    this.reactor,
    required this.engine,
    this.mounts = const [],
  });

  /// The globally unique identifier of the ship.
  String symbol;

  ShipRegistration registration;

  ShipNav nav;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ScannedShipFrame? frame;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ScannedShipReactor? reactor;

  ScannedShipEngine engine;

  List<ScannedShipMountsInner> mounts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedShip &&
          other.symbol == symbol &&
          other.registration == registration &&
          other.nav == nav &&
          other.frame == frame &&
          other.reactor == reactor &&
          other.engine == engine &&
          other.mounts == mounts;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (registration.hashCode) +
      (nav.hashCode) +
      (frame == null ? 0 : frame!.hashCode) +
      (reactor == null ? 0 : reactor!.hashCode) +
      (engine.hashCode) +
      (mounts.hashCode);

  @override
  String toString() =>
      'ScannedShip[symbol=$symbol, registration=$registration, nav=$nav, frame=$frame, reactor=$reactor, engine=$engine, mounts=$mounts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'registration'] = this.registration;
    json[r'nav'] = this.nav;
    if (this.frame != null) {
      json[r'frame'] = this.frame;
    } else {
      json[r'frame'] = null;
    }
    if (this.reactor != null) {
      json[r'reactor'] = this.reactor;
    } else {
      json[r'reactor'] = null;
    }
    json[r'engine'] = this.engine;
    json[r'mounts'] = this.mounts;
    return json;
  }

  /// Returns a new [ScannedShip] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ScannedShip? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ScannedShip[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ScannedShip[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ScannedShip(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        registration: ShipRegistration.fromJson(json[r'registration'])!,
        nav: ShipNav.fromJson(json[r'nav'])!,
        frame: ScannedShipFrame.fromJson(json[r'frame']),
        reactor: ScannedShipReactor.fromJson(json[r'reactor']),
        engine: ScannedShipEngine.fromJson(json[r'engine'])!,
        mounts:
            ScannedShipMountsInner.listFromJson(json[r'mounts']) ?? const [],
      );
    }
    return null;
  }

  static List<ScannedShip>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ScannedShip>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ScannedShip.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ScannedShip> mapFromJson(dynamic json) {
    final map = <String, ScannedShip>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScannedShip.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ScannedShip-objects as value to a dart map
  static Map<String, List<ScannedShip>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ScannedShip>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScannedShip.listFromJson(
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
    'registration',
    'nav',
    'engine',
  };
}
