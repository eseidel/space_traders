//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Ship {
  /// Returns a new [Ship] instance.
  Ship({
    required this.symbol,
    required this.registration,
    required this.nav,
    required this.crew,
    required this.frame,
    required this.reactor,
    required this.engine,
    required this.cooldown,
    this.modules = const [],
    this.mounts = const [],
    required this.cargo,
    required this.fuel,
  });

  /// The globally unique identifier of the ship in the following format: `[AGENT_SYMBOL]-[HEX_ID]`
  String symbol;

  ShipRegistration registration;

  ShipNav nav;

  ShipCrew crew;

  ShipFrame frame;

  ShipReactor reactor;

  ShipEngine engine;

  Cooldown cooldown;

  /// Modules installed in this ship.
  List<ShipModule> modules;

  /// Mounts installed in this ship.
  List<ShipMount> mounts;

  ShipCargo cargo;

  ShipFuel fuel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ship &&
          other.symbol == symbol &&
          other.registration == registration &&
          other.nav == nav &&
          other.crew == crew &&
          other.frame == frame &&
          other.reactor == reactor &&
          other.engine == engine &&
          other.cooldown == cooldown &&
          other.modules == modules &&
          other.mounts == mounts &&
          other.cargo == cargo &&
          other.fuel == fuel;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (registration.hashCode) +
      (nav.hashCode) +
      (crew.hashCode) +
      (frame.hashCode) +
      (reactor.hashCode) +
      (engine.hashCode) +
      (cooldown.hashCode) +
      (modules.hashCode) +
      (mounts.hashCode) +
      (cargo.hashCode) +
      (fuel.hashCode);

  @override
  String toString() =>
      'Ship[symbol=$symbol, registration=$registration, nav=$nav, crew=$crew, frame=$frame, reactor=$reactor, engine=$engine, cooldown=$cooldown, modules=$modules, mounts=$mounts, cargo=$cargo, fuel=$fuel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'registration'] = this.registration;
    json[r'nav'] = this.nav;
    json[r'crew'] = this.crew;
    json[r'frame'] = this.frame;
    json[r'reactor'] = this.reactor;
    json[r'engine'] = this.engine;
    json[r'cooldown'] = this.cooldown;
    json[r'modules'] = this.modules;
    json[r'mounts'] = this.mounts;
    json[r'cargo'] = this.cargo;
    json[r'fuel'] = this.fuel;
    return json;
  }

  /// Returns a new [Ship] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Ship? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Ship[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Ship[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Ship(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        registration: ShipRegistration.fromJson(json[r'registration'])!,
        nav: ShipNav.fromJson(json[r'nav'])!,
        crew: ShipCrew.fromJson(json[r'crew'])!,
        frame: ShipFrame.fromJson(json[r'frame'])!,
        reactor: ShipReactor.fromJson(json[r'reactor'])!,
        engine: ShipEngine.fromJson(json[r'engine'])!,
        cooldown: Cooldown.fromJson(json[r'cooldown'])!,
        modules: ShipModule.listFromJson(json[r'modules']),
        mounts: ShipMount.listFromJson(json[r'mounts']),
        cargo: ShipCargo.fromJson(json[r'cargo'])!,
        fuel: ShipFuel.fromJson(json[r'fuel'])!,
      );
    }
    return null;
  }

  static List<Ship> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Ship>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Ship.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Ship> mapFromJson(dynamic json) {
    final map = <String, Ship>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Ship.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Ship-objects as value to a dart map
  static Map<String, List<Ship>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Ship>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Ship.listFromJson(
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
    'registration',
    'nav',
    'crew',
    'frame',
    'reactor',
    'engine',
    'cooldown',
    'modules',
    'mounts',
    'cargo',
    'fuel',
  };
}
