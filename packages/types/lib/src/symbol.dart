import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Type-safe representation of a Waypoint Symbol
@immutable
class WaypointSymbol {
  const WaypointSymbol._(this.waypoint, this.system);

  /// Create a WaypointSymbol from a json string.
  factory WaypointSymbol.fromJson(String json) =>
      WaypointSymbol.fromString(json);

  /// Create a WaypointSymbol from a string.
  factory WaypointSymbol.fromString(String symbol) {
    if (_countHyphens(symbol) != 2) {
      throw ArgumentError('Invalid waypoint symbol: $symbol');
    }
    final systemSymbol = SystemSymbol.fromString(
      symbol.substring(0, symbol.lastIndexOf('-')),
    );
    return WaypointSymbol._(symbol, systemSymbol);
  }

  /// Create a WaypointSymbol from json or null if the json is null.
  static WaypointSymbol? fromJsonOrNull(String? json) =>
      json == null ? null : WaypointSymbol.fromJson(json);

  /// The full waypoint symbol.
  final String waypoint;

  /// The system symbol of the waypoint.
  final SystemSymbol system;

  /// The sector symbol of the waypoint.
  String get sector {
    // Avoid splitting the string if we don't have to.
    final firstHyphen = waypoint.indexOf('-');
    return waypoint.substring(0, firstHyphen);
  }

  /// Just the waypoint name (no sector or system)
  String get waypointName {
    // Avoid splitting the string if we don't have to.
    final lastHyphen = waypoint.lastIndexOf('-');
    return waypoint.substring(lastHyphen + 1);
  }

  /// Returns true if the waypoint is from the given system.
  /// Faster than converting to a SystemSymbol and comparing.
  // TODO(eseidel): This can be removed now.
  bool hasSystem(SystemSymbol systemSymbol) {
    // Avoid constructing a new SystemSymbol if we don't have to.
    return system == systemSymbol;
  }

  /// Returns the System as a string to pass to OpenAPI.
  String get systemString => system.system;

  /// Just the system and waypoint name (no sector)
  String get sectorLocalName {
    // Avoid splitting the string if we don't have to.
    final firstHyphen = waypoint.indexOf('-');
    return waypoint.substring(firstHyphen + 1);
  }

  @override
  String toString() => sectorLocalName;

  /// Returns the json representation of the waypoint.
  String toJson() => waypoint;

  // Use a direct override rather than Equatable, because this code is
  // extremely hot.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaypointSymbol &&
          runtimeType == other.runtimeType &&
          waypoint == other.waypoint;

  @override
  int get hashCode => waypoint.hashCode;
}

// We used to use split(), but that shows up in hot code paths.
/// Returns the number of hypens in the given string.
int _countHyphens(String str) {
  var count = 0;
  for (var i = 0; i < str.length; i++) {
    if (str[i] == '-') {
      count++;
    }
  }
  return count;
}

/// Type-safe representation of a System Symbol
@immutable
class SystemSymbol {
  const SystemSymbol._(this.system);

  /// Create a SystemSymbol from a string.
  factory SystemSymbol.fromString(String symbol) {
    if (_countHyphens(symbol) != 1) {
      throw ArgumentError('Invalid system symbol: $symbol');
    }
    return SystemSymbol._(symbol);
  }

  /// Create a SystemSymbol from a json string.
  factory SystemSymbol.fromJson(String json) => SystemSymbol.fromString(json);

  /// The sector symbol of the system.
  String get sector {
    // Avoid splitting the string if we don't have to.
    final firstHyphen = system.indexOf('-');
    return system.substring(0, firstHyphen);
  }

  /// Just the system name (no sector)
  String get systemName {
    // Avoid splitting the string if we don't have to.
    final lastHyphen = system.lastIndexOf('-');
    return system.substring(lastHyphen + 1);
  }

  /// The full system symbol.
  final String system;

  /// Convert to JSON.
  String toJson() => system;

  @override
  String toString() => system;

  // Use a direct override rather than Equatable, because this code is
  // extremely hot.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemSymbol &&
          runtimeType == other.runtimeType &&
          system == other.system;

  @override
  int get hashCode => system.hashCode;
}

/// Parsed ShipSymbol which can be compared/sorted.
@immutable
class ShipSymbol extends Equatable implements Comparable<ShipSymbol> {
  /// Create a ShipSymbol from name and number part.
  /// The number part is given in decimal, but will be represented in hex.
  const ShipSymbol(this.agentName, this.number);

  /// Create a dummy ShipSymbol for testing.
  @visibleForTesting
  const ShipSymbol.fallbackValue()
      : agentName = 'S',
        number = 0;

  /// Create a ShipSymbol from a string.
  ShipSymbol.fromString(String symbol)
      : agentName = _parseAgentName(symbol),
        number = int.parse(symbol.split('-').last, radix: 16);

  /// Create a ShipSymbol from a json string.
  factory ShipSymbol.fromJson(String json) => ShipSymbol.fromString(json);

  static String _parseAgentName(String symbol) {
    final parts = symbol.split('-');
    // Hyphens are allowed in the agent name, but the last part is always the
    // number, there must be at least one hyphen.
    if (parts.length < 2) {
      throw ArgumentError('Invalid ship symbol: $symbol');
    }
    final nameParts = parts.sublist(0, parts.length - 1);
    return nameParts.join('-');
  }

  /// The name part of the ship symbol.
  final String agentName;

  /// The number part of the ship symbol.
  final int number;

  @override
  List<Object> get props => [agentName, number];

  /// The number part in hex.
  String get hexNumber => number.toRadixString(16).toUpperCase();

  /// The full ship symbol.
  String get symbol => '$agentName-$hexNumber';

  @override
  int compareTo(ShipSymbol other) {
    final nameCompare = agentName.compareTo(other.agentName);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return number.compareTo(other.number);
  }

  @override
  String toString() => symbol;

  /// Returns the json representation of the ship symbol.
  String toJson() => symbol;
}
