import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:openapi/api.dart' as openapi;
import 'package:types/types.dart';

/// A type representing the unchanging values of a waypoint.
@immutable
class SystemWaypoint extends Equatable {
  /// Returns a new [SystemWaypoint] instance.
  SystemWaypoint({
    required this.symbol,
    required this.type,
    required this.position,
    this.orbitals = const [],
    this.orbits,
  }) : assert(
         position.system == symbol.system,
         'Position system must match symbol system.',
       );

  /// Creates a new [SystemWaypoint] from an OpenAPI [openapi.SystemWaypoint].
  factory SystemWaypoint.fromOpenApi(openapi.SystemWaypoint waypoint) {
    final waypointSymbol = WaypointSymbol.fromJson(waypoint.symbol);
    return SystemWaypoint(
      symbol: waypointSymbol,
      type: waypoint.type,
      position: WaypointPosition(waypoint.x, waypoint.y, waypointSymbol.system),
      orbitals: waypoint.orbitals,
      orbits: WaypointSymbol.fromJsonOrNull(waypoint.orbits),
    );
  }

  /// Creates a new [SystemWaypoint] from JSON.
  factory SystemWaypoint.fromJson(Map<String, dynamic> json) {
    final openapiWaypoint = openapi.SystemWaypoint.fromJson(json)!;
    return SystemWaypoint.fromOpenApi(openapiWaypoint);
  }

  /// Create a new [SystemWaypoint] for testing.
  @visibleForTesting
  SystemWaypoint.test(
    this.symbol, {
    this.type = WaypointType.ASTEROID,
    WaypointPosition? position,
  }) : position = position ?? WaypointPosition(0, 0, symbol.system),
       orbitals = const [],
       orbits = null;

  /// The symbol of the waypoint.
  final WaypointSymbol symbol;

  /// The symbol of the system.
  SystemSymbol get system => symbol.system;

  /// The type of the waypoint.
  final openapi.WaypointType type;

  /// The position of the waypoint.
  final WaypointPosition position;

  /// Waypoints that orbit this waypoint.
  final List<WaypointOrbital> orbitals;

  /// The symbol of the parent waypoint, if this waypoint is in orbit around
  /// another waypoint.
  final WaypointSymbol? orbits;

  /// Returns true if the waypoint has the given type.
  bool isType(WaypointType type) => this.type == type;

  /// Returns true if the waypoint is an asteroid field.
  bool get isAsteroid => isType(WaypointType.ASTEROID);

  /// Returns true if the waypoint is a jump gate.
  bool get isJumpGate => isType(WaypointType.JUMP_GATE);

  /// Returns the distance to the given waypoint.
  double distanceTo(SystemWaypoint other) =>
      position.distanceTo(other.position);

  /// Converts to [openapi.ShipNavRouteWaypoint].
  @visibleForTesting
  ShipNavRouteWaypoint toShipNavRouteWaypoint() {
    return ShipNavRouteWaypoint(
      symbol: symbol.waypoint,
      type: type,
      systemSymbol: symbol.systemString,
      x: position.x,
      y: position.y,
    );
  }

  /// Converts to [openapi.SystemWaypoint].
  @protected
  openapi.SystemWaypoint toOpenApi() {
    return openapi.SystemWaypoint(
      symbol: symbol.toJson(),
      type: type,
      x: position.x,
      y: position.y,
      orbitals: orbitals,
      orbits: orbits?.toJson(),
    );
  }

  /// Call toJson on the OpenAPI object and fix any issues.
  static Map<String, dynamic> openApiToJson(openapi.SystemWaypoint waypoint) {
    final json = waypoint.toJson();
    json['type'] = (json['type'] as WaypointType).toJson();
    return json;
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return openApiToJson(toOpenApi());
  }

  @override
  List<Object?> get props => [symbol, type, position, orbitals, orbits];
}

/// A type representing a system as it exists in the database.
@immutable
class SystemRecord extends Equatable {
  /// Returns a new [SystemRecord] instance.
  const SystemRecord({
    required this.symbol,
    required this.type,
    required this.position,
    required this.waypointSymbols,
  });

  /// Create a new [System] for testing.
  @visibleForTesting
  const SystemRecord.test(
    this.symbol, {
    this.type = SystemType.BLACK_HOLE,
    this.position = const SystemPosition(0, 0),
    this.waypointSymbols = const [],
  });

  /// The symbol of the system.
  final SystemSymbol symbol;

  /// The type of the system.
  final SystemType type;

  /// The position of the system.
  final SystemPosition position;

  /// The waypoints in the system.
  final List<WaypointSymbol> waypointSymbols;

  /// Returns the distance to the given system.
  double distanceTo(SystemRecord other) => position.distanceTo(other.position);

  @override
  List<Object?> get props => [symbol, type, position, waypointSymbols];
}

/// Type representing a system.
@immutable
class System extends Equatable {
  /// Returns a new [System] instance.
  System({
    required this.symbol,
    required this.type,
    required this.position,
    this.waypoints = const [],
    this.factions = const [],
  }) : sectorSymbol = symbol.sector;

  /// Create a new [System] from a [SystemRecord].
  factory System.fromRecord(
    SystemRecord record,
    List<SystemWaypoint> waypoints,
  ) {
    return System(
      symbol: record.symbol,
      type: record.type,
      position: record.position,
      waypoints: waypoints,
      // Ignoring factions for now.
    );
  }

  /// Create a new [System] from JSON.
  factory System.fromJson(Map<String, dynamic> json) {
    final openapiSystem = openapi.System.fromJson(json)!;
    return System.fromOpenApi(openapiSystem);
  }

  /// Creates a new [System] from an OpenAPI [openapi.System].
  factory System.fromOpenApi(openapi.System system) {
    return System(
      symbol: SystemSymbol.fromJson(system.symbol),
      type: system.type,
      position: SystemPosition(system.x, system.y),
      waypoints: system.waypoints.map(SystemWaypoint.fromOpenApi).toList(),
      factions: system.factions,
    );
  }

  /// Create a new [System] for testing.
  @visibleForTesting
  System.test(
    this.symbol, {
    this.type = SystemType.BLACK_HOLE,
    this.position = const SystemPosition(0, 0),
    this.waypoints = const [],
    this.factions = const [],
  }) : sectorSymbol = symbol.sector;

  /// The symbol of the system.
  final SystemSymbol symbol;

  /// The symbol of the sector.
  final String sectorSymbol;

  /// The type of the system.
  final SystemType type;

  /// The position of the system.
  final SystemPosition position;

  /// Waypoints in this system.
  final List<SystemWaypoint> waypoints;

  /// Factions that control this system.
  final List<SystemFaction> factions;

  /// Returns the the SystemWaypoint for the jump gate if it has one.
  Iterable<SystemWaypoint> get jumpGateWaypoints =>
      waypoints.where((w) => w.isJumpGate);

  /// Returns true if the system has a jump gate.
  bool get hasJumpGate => waypoints.any((w) => w.isJumpGate);

  /// Returns the distance to the given system.
  double distanceTo(System other) => position.distanceTo(other.position);

  /// Converts to a [SystemRecord].
  SystemRecord toSystemRecord() => SystemRecord(
    symbol: symbol,
    type: type,
    position: position,
    waypointSymbols: waypoints.map((w) => w.symbol).toList(),
  );

  /// Converts to [openapi.System].
  @visibleForTesting
  openapi.System toOpenApi() {
    return openapi.System(
      symbol: symbol.toJson(),
      type: type,
      sectorSymbol: sectorSymbol,
      x: position.x,
      y: position.y,
      waypoints: waypoints.map((w) => w.toOpenApi()).toList(),
      factions: factions,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    final json = toOpenApi().toJson();
    // Work around a bug in OpenApi's generated toJson method where it doesn't
    // recursively call toJson.
    json['type'] = (json['type'] as SystemType).toJson();
    json['waypoints'] =
        (json['waypoints'] as List<openapi.SystemWaypoint>)
            .map(SystemWaypoint.openApiToJson)
            .toList();
    return json;
  }

  @override
  List<Object?> get props => [symbol, type, position, waypoints, factions];
}

// While we keep an immutable version of the waypoint in the database, the
// waypoint is mutable in the game, including chart, isUnderConstruction,
// modifiers, etc.  So we do not make this Equatable.
@immutable
/// Type representing a waypoint.
class Waypoint {
  /// Returns a new [Waypoint] instance.
  Waypoint({
    required this.symbol,
    required this.type,
    required this.position,
    required this.isUnderConstruction,
    this.orbitals = const [],
    this.orbits,
    this.faction,
    this.traits = const [],
    this.modifiers = const [],
    this.chart,
  }) : assert(
         position.system == symbol.system,
         'Position system must match symbol system.',
       );

  /// Create a new [Waypoint] for testing.
  @visibleForTesting
  Waypoint.test(
    this.symbol, {
    WaypointPosition? position,
    this.type = WaypointType.ASTEROID,
    this.traits = const [],
  }) : position = position ?? WaypointPosition(0, 0, symbol.system),
       isUnderConstruction = false,
       orbitals = const [],
       orbits = null,
       faction = null,
       modifiers = const [],
       chart = null;

  /// Create a new [Waypoint] from JSON.
  factory Waypoint.fromJson(Map<String, dynamic> json) {
    final openapiWaypoint = openapi.Waypoint.fromJson(json)!;
    return Waypoint.fromOpenApi(openapiWaypoint);
  }

  /// Creates a new [Waypoint] from an OpenAPI [openapi.Waypoint].
  factory Waypoint.fromOpenApi(openapi.Waypoint waypoint) {
    final systemSymbol = SystemSymbol.fromString(waypoint.systemSymbol);
    return Waypoint(
      symbol: WaypointSymbol.fromJson(waypoint.symbol),
      type: waypoint.type,
      position: WaypointPosition(waypoint.x, waypoint.y, systemSymbol),
      isUnderConstruction: waypoint.isUnderConstruction,
      orbitals: waypoint.orbitals,
      orbits: WaypointSymbol.fromJsonOrNull(waypoint.orbits),
      faction: waypoint.faction,
      traits: waypoint.traits,
      modifiers: waypoint.modifiers,
      chart: waypoint.chart,
    );
  }

  /// The symbol of the waypoint.
  final WaypointSymbol symbol;

  /// The type of the waypoint.
  final WaypointType type;

  /// The symbol of the system.
  SystemSymbol get system => symbol.system;

  /// Position of the waypoint.
  final WaypointPosition position;

  /// Waypoints that orbit this waypoint.
  final List<WaypointOrbital> orbitals;

  /// The symbol of the parent waypoint, if this waypoint is in orbit around
  /// another waypoint.
  final WaypointSymbol? orbits;

  /// The faction that controls the waypoint, if any.
  final WaypointFaction? faction;

  /// The traits of the waypoint.
  final List<WaypointTrait> traits;

  /// The modifiers of the waypoint.
  final List<WaypointModifier> modifiers;

  /// The chart of the waypoint if it is charted.
  final Chart? chart;

  /// True if the waypoint is under construction.
  final bool isUnderConstruction;

  /// Converts the waypoint to a SystemWaypoint.
  SystemWaypoint toSystemWaypoint() {
    return SystemWaypoint(symbol: symbol, type: type, position: position);
  }

  /// Returns true if the waypoint has the given trait.
  bool hasTrait(WaypointTraitSymbol trait) =>
      traits.any((t) => t.symbol == trait);

  /// Returns true if the waypoint has the given type.
  bool isType(WaypointType type) => this.type == type;

  /// Returns true if the waypoint can be mined.
  bool get canBeMined => traits.any((t) => isMinableTrait(t.symbol));

  /// Returns true if the waypoint can be siphoned.
  bool get canBeSiphoned => isType(WaypointType.GAS_GIANT);

  /// Returns true if the waypoint is a jump gate.
  bool get isJumpGate => isType(WaypointType.JUMP_GATE);

  /// Returns true if the waypoint has been charted.
  bool get isCharted => chart != null;

  /// Returns true if the waypoint has a shipyard.
  bool get hasShipyard => hasTrait(WaypointTraitSymbol.SHIPYARD);

  /// Returns true if the waypoint has a marketplace.
  bool get hasMarketplace => hasTrait(WaypointTraitSymbol.MARKETPLACE);

  /// Returns the distance to the given waypoint.
  double distanceTo(Waypoint other) => position.distanceTo(other.position);

  /// Converts to [openapi.Waypoint].
  @visibleForTesting
  openapi.Waypoint toOpenApi() {
    return openapi.Waypoint(
      symbol: symbol.toJson(),
      type: type,
      systemSymbol: symbol.systemString,
      x: position.x,
      y: position.y,
      isUnderConstruction: isUnderConstruction,
      orbitals: orbitals,
      orbits: orbits?.toJson(),
      faction: faction,
      traits: traits,
      modifiers: modifiers,
      chart: chart,
    );
  }

  // Work around a bug in OpenApi's generated toJson method where it doesn't
  // recursively call toJson.
  /// Call toJson on the OpenAPI object and fix any issues.
  static Map<String, dynamic> openApiToJson(openapi.Waypoint waypoint) {
    Map<String, dynamic> traitToJson(WaypointTrait trait) {
      final json = trait.toJson();
      json['symbol'] = trait.symbol.toJson();
      return json;
    }

    final json = waypoint.toJson();
    json['traits'] =
        (json['traits'] as List<WaypointTrait>).map(traitToJson).toList();
    json['type'] = (json['type'] as WaypointType).toJson();
    return json;
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return openApiToJson(toOpenApi());
  }
}
