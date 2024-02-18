import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:openapi/api.dart' as openapi;
import 'package:types/types.dart';

/// A cached JumpGate value.
@immutable
class JumpGate extends Equatable {
  /// Creates a new JumpGate.
  const JumpGate({
    required this.waypointSymbol,
    required this.connections,
  });

  /// Creates a new  from a JumpGate.
  factory JumpGate.fromOpenApi(openapi.JumpGate jumpGate) {
    return JumpGate(
      waypointSymbol: WaypointSymbol.fromJson(jumpGate.symbol),
      connections: jumpGate.connections.map(WaypointSymbol.fromString).toSet(),
    );
  }

  /// Creates a new JumpGate from JSON.
  factory JumpGate.fromJson(Map<String, dynamic> json) {
    return JumpGate(
      connections: (json['connections'] as List<dynamic>)
          .map((dynamic e) => e as String)
          .map(WaypointSymbol.fromJson)
          .toSet(),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
    );
  }

  /// The waypoint symbol.
  final WaypointSymbol waypointSymbol;

  /// The connections for this jump gate.
  final Set<WaypointSymbol> connections;

  /// The connected system symbols.
  Set<SystemSymbol> get connectedSystemSymbols =>
      connections.map((e) => e.system).toSet();

  /// Converts this object to an OpenAPI object.
  openapi.JumpGate toOpenApi() {
    return openapi.JumpGate(
      symbol: waypointSymbol.toJson(),
      connections: connections.map((e) => e.toJson()).toList(),
    );
  }

  @override
  List<Object?> get props => [waypointSymbol, connections];

  /// Converts this object to a JSON encodable object.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'connections': connections.map((e) => e.toJson()).sorted(),
        'waypointSymbol': waypointSymbol.toJson(),
      };
}
