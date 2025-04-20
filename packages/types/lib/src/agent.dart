import 'package:equatable/equatable.dart';
import 'package:openapi/api.dart' as openapi;
import 'package:types/types.dart';

/// An agent in the game.
class Agent extends Equatable {
  /// Creates a new agent.
  const Agent({
    required this.symbol,
    required this.headquarters,
    required this.credits,
    required this.startingFaction,
    required this.shipCount,
    this.accountId,
  });

  /// Creates a test agent.
  Agent.test({
    this.symbol = 'A',
    WaypointSymbol? headquarters,
    this.credits = 1000000,
    FactionSymbol? startingFaction,
    this.shipCount = 1,
    this.accountId,
  }) : headquarters = headquarters ?? WaypointSymbol.fromString('S-A-W'),
       startingFaction = startingFaction ?? FactionSymbol.AEGIS;

  /// Creates an agent from an OpenAPI agent.
  factory Agent.fromOpenApi(openapi.Agent agent) {
    return Agent(
      symbol: agent.symbol,
      headquarters: WaypointSymbol.fromString(agent.headquarters),
      credits: agent.credits,
      startingFaction: FactionSymbol.fromJson(agent.startingFaction)!,
      shipCount: agent.shipCount,
      accountId: agent.accountId,
    );
  }

  /// The symbol of the agent.
  final String symbol;

  /// The symbol of the waypoint that is the agent's headquarters.
  final WaypointSymbol headquarters;

  /// The amount of credits the agent has.
  final int credits;

  /// The faction the agent started with.
  final FactionSymbol startingFaction;

  /// The number of ships the agent has.
  final int shipCount;

  /// The account ID of the agent.
  final String? accountId;

  @override
  List<Object?> get props => [
    symbol,
    headquarters,
    credits,
    startingFaction,
    shipCount,
    accountId,
  ];

  /// Converts this agent to an OpenAPI agent.
  openapi.Agent toOpenApi() {
    return openapi.Agent(
      symbol: symbol,
      headquarters: headquarters.waypoint,
      credits: credits,
      startingFaction: startingFaction.value,
      shipCount: shipCount,
      accountId: accountId,
    );
  }
}
