import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query to get an agent by symbol.
Query agentBySymbolQuery(String agentSymbol) => Query(
  'SELECT * FROM agent_ WHERE symbol = @symbol',
  parameters: {
    // TODO(eseidel): use an AgentSymbol type.
    'symbol': agentSymbol.toUpperCase(),
  },
);

/// Convert an agent to a map of column values.
Map<String, dynamic> agentToColumnMap(Agent agent) => {
  'symbol': agent.symbol,
  'headquarters': agent.headquarters.toJson(),
  'credits': agent.credits,
  'starting_faction': agent.startingFaction.toJson(),
  'ship_count': agent.shipCount,
  'account_id': agent.accountId,
};

/// Convert a map of column values to an agent.
Agent agentFromColumnMap(Map<String, dynamic> values) {
  return Agent(
    symbol: values['symbol'] as String,
    headquarters: WaypointSymbol.fromJson(values['headquarters'] as String),
    credits: values['credits'] as int,
    startingFaction: FactionSymbol.fromJson(
      values['starting_faction'] as String,
    ),
    shipCount: values['ship_count'] as int,
    accountId: values['account_id'] as String,
  );
}

/// Update the given agent in the database.
Query upsertAgentQuery(Agent agent) =>
    Query(parameters: agentToColumnMap(agent), '''
      INSERT INTO agent_ (symbol, headquarters, credits, starting_faction, ship_count, account_id)
      VALUES (@symbol, @headquarters, @credits, @starting_faction, @ship_count, @account_id)
      ON CONFLICT (symbol) DO UPDATE SET
        headquarters = @headquarters,
        credits = @credits,
        starting_faction = @starting_faction,
        ship_count = @ship_count,
        account_id = @account_id
      ''');
