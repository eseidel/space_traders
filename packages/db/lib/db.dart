import 'package:db/config.dart';
import 'package:db/src/agent.dart';
import 'package:db/src/behavior.dart';
import 'package:db/src/chart.dart';
import 'package:db/src/construction.dart';
import 'package:db/src/contract.dart';
import 'package:db/src/extraction.dart';
import 'package:db/src/faction.dart';
import 'package:db/src/jump_gate.dart';
import 'package:db/src/market_listing.dart';
import 'package:db/src/market_price.dart';
import 'package:db/src/query.dart';
import 'package:db/src/queue.dart';
import 'package:db/src/ship.dart';
import 'package:db/src/shipyard_listing.dart';
import 'package:db/src/shipyard_price.dart';
import 'package:db/src/survey.dart';
import 'package:db/src/transaction.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:types/types.dart';

export 'package:db/config.dart';

/// Connect to the default local database.
/// Logs and returns null on failure.
Future<Database> defaultDatabase({
  @visibleForTesting
  Future<pg.Connection> Function(pg.Endpoint endpoint, pg.ConnectionSettings?)
      openConnection =
      _defaultOpenConnection,
}) async {
  final db = Database(
    defaultDatabaseEndpoint,
    settings: defaultDatabaseConnectionSettings,
  );
  await db.open(openConnection: openConnection);
  return db;
}

Future<pg.Connection> _defaultOpenConnection(
  pg.Endpoint endpoint,
  pg.ConnectionSettings? settings,
) {
  return pg.Connection.open(endpoint, settings: settings);
}

/// Wrapper around a database connection.
class DatabaseConnection {
  /// Create a new database connection.
  DatabaseConnection(this._connection);

  /// The underlying connection, private to this class.  Methods on this class
  /// should use execute().
  final pg.Connection _connection;

  /// The number of queries made.
  final QueryCounts queryCounts = QueryCounts();

  /// Close the database connection.
  Future<void> close() => _connection.close();

  /// Wait for a notification on a channel.
  Future<void> waitOnChannel(String channel) async {
    await _connection.channels[channel].first;
  }

  /// Execute a query.
  Future<pg.Result> execute(Query query) {
    queryCounts.record(query.fmtString);
    return _connection.execute(
      pg.Sql.named(query.fmtString),
      parameters: query.parameters,
    );
  }

  /// Execute a query.
  Future<pg.Result> executeSql(String sql) {
    queryCounts.record(sql);
    return _connection.execute(sql);
  }
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.endpoint, {this.settings});

  /// Create a new database with mock connection for testing.
  @visibleForTesting
  Database.test(this._connection)
    : endpoint = pg.Endpoint(host: 'localhost', database: 'test'),
      settings = null;

  /// Configure the database connection.
  final pg.Endpoint endpoint;

  /// Configure the database connection.
  final pg.ConnectionSettings? settings;

  late final DatabaseConnection _connection;

  /// The number of queries made.
  QueryCounts get queryCounts => _connection.queryCounts;

  /// Open the database connection.
  Future<void> open({
    @visibleForTesting
    Future<pg.Connection> Function(
          pg.Endpoint endpoint,
          pg.ConnectionSettings? settings,
        )
        openConnection =
        _defaultOpenConnection,
  }) async {
    _connection = DatabaseConnection(await openConnection(endpoint, settings));
  }

  /// Close the database connection.
  Future<void> close() => _connection.close();

  /// Listen for notifications on a channel.
  Future<void> listen(String channel) async {
    await executeSql('LISTEN $channel');
  }

  /// Notify listeners on a channel.
  Future<void> notify(String channel, [Object? payload]) async {
    if (payload == null) {
      await executeSql('NOTIFY $channel');
    } else {
      await executeSql("NOTIFY $channel, '$payload'");
    }
  }

  /// Wait for a notification on a channel.
  Future<void> waitOnChannel(String channel) async {
    await _connection.waitOnChannel(channel);
  }

  /// Execute a query.
  @protected
  Future<pg.Result> execute(Query query) => _connection.execute(query);

  /// Execute a query.
  @protected
  Future<pg.Result> executeSql(String sql) => _connection.executeSql(sql);

  /// Query for multiple records using the provided query.
  @protected
  Future<Iterable<T>> queryMany<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return execute(
      query,
    ).then((result) => result.map((r) => r.toColumnMap()).map(fromColumnMap));
  }

  /// Query for a single record using the provided query.
  @protected
  Future<T?> queryOne<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return execute(query).then(
      (result) =>
          result.isEmpty ? null : fromColumnMap(result.first.toColumnMap()),
    );
  }

  /// Return a list of all table names.
  Future<Iterable<String>> allTableNames() async {
    final result = await executeSql(
      'SELECT table_name FROM information_schema.tables '
      "WHERE table_schema = 'public' "
      'ORDER BY table_name',
    );
    return result.map((r) => r.first! as String);
  }

  /// Return the number of rows in the given table.
  Future<int> rowsInTable(String tableName) async {
    final result = await executeSql('SELECT COUNT(*) FROM $tableName');
    return result[0][0]! as int;
  }

  /// Insert a transaction into the database.
  Future<void> insertTransaction(Transaction transaction) async {
    await execute(insertTransactionQuery(transaction));
  }

  /// Insert a survey into the database.
  Future<void> insertSurvey(HistoricalSurvey survey) async {
    await execute(insertSurveyQuery(survey));
  }

  /// Return the most recent surveys.
  Future<Iterable<HistoricalSurvey>> recentSurveysAtWaypoint(
    WaypointSymbol waypointSymbol, {
    required int count,
  }) async {
    final query = recentSurveysAtWaypointQuery(
      waypointSymbol: waypointSymbol,
      count: count,
    );
    return queryMany(query, surveyFromColumnMap);
  }

  /// Return all surveys.
  Future<Iterable<HistoricalSurvey>> allSurveys() async =>
      queryMany(allSurveysQuery(), surveyFromColumnMap);

  /// Mark the given survey as exhausted.
  Future<void> markSurveyExhausted(Survey survey) async {
    final query = markSurveyExhaustedQuery(survey);
    final result = await execute(query);
    if (result.affectedRows != 1) {
      throw ArgumentError('Survey not found: $survey');
    }
  }

  /// Gets all factions.
  Future<Iterable<Faction>> allFactions() =>
      queryMany(allFactionsQuery(), factionFromColumnMap);

  /// Cache the given factions.
  Future<void> upsertFaction(Faction faction) async {
    await execute(upsertFactionQuery(faction));
  }

  /// Return all extractions.
  Future<Iterable<ExtractionRecord>> allExtractions() async =>
      queryMany(allExtractionsQuery(), extractionFromColumnMap);

  /// Insert an extraction into the database.
  Future<void> insertExtraction(ExtractionRecord extraction) async =>
      execute(insertExtractionQuery(extraction));

  /// Get a construction record from the database.
  Future<ConstructionRecord?> getConstructionRecord(
    WaypointSymbol waypointSymbol,
    Duration maxAge,
  ) => queryOne(
    getConstructionQuery(waypointSymbol, maxAge),
    constructionFromColumnMap,
  );

  /// Return all construction records.
  Future<Iterable<ConstructionRecord>> allConstructionRecords() async =>
      queryMany(allConstructionQuery(), constructionFromColumnMap);

  /// Insert a construction record into the database.
  Future<void> upsertConstruction(ConstructionRecord record) async =>
      execute(upsertConstructionQuery(record));

  /// Return all charting records.
  Future<Iterable<ChartingRecord>> allChartingRecords() async =>
      queryMany(allChartingRecordsQuery(), chartingRecordFromColumnMap);

  /// Insert a charting record into the database.
  Future<void> upsertChartingRecord(ChartingRecord record) async =>
      execute(upsertChartingRecordQuery(record));

  /// Get a charting record from the database.
  Future<ChartingRecord?> getChartingRecord(
    WaypointSymbol waypointSymbol,
    Duration maxAge,
  ) => queryOne(
    getChartingRecordQuery(waypointSymbol, maxAge),
    chartingRecordFromColumnMap,
  );

  /// Return the next request to be executed.
  Future<RequestRecord?> nextRequest() =>
      queryOne(nextRequestQuery(), requestRecordFromColumnMap);

  /// Insert the given request into the database and return it's new id.
  Future<int> insertRequest(RequestRecord request) async {
    final query = insertRequestQuery(request);
    final result = await execute(query);
    return result.first.first! as int;
  }

  /// Get the request with the given id.
  Future<RequestRecord?> getRequest(int requestId) async {
    final query = getRequestQuery(requestId);
    return queryOne(query, requestRecordFromColumnMap);
  }

  /// Delete the given request from the database.
  Future<void> deleteRequest(RequestRecord request) async {
    final query = deleteRequestQuery(request);
    final result = await execute(query);
    if (result.affectedRows != 1) {
      throw ArgumentError('Request not found: $request');
    }
  }

  /// Insert the given response into the database.
  Future<void> insertResponse(ResponseRecord response) async {
    await execute(insertResponseQuery(response));
  }

  /// Get the response with the given id.
  Future<ResponseRecord?> getResponseForRequest(int requestId) async {
    final query = getResponseForRequestQuery(requestId);
    return queryOne(query, responseRecordFromColumnMap);
  }

  /// Delete responses older than the given age.
  Future<void> deleteResponsesBefore(DateTime timestamp) {
    return execute(
      Query(
        'DELETE FROM response_ WHERE created_at < @timestamp',
        parameters: {'timestamp': timestamp},
      ),
    );
  }

  /// Get my agent from the db.
  Future<Agent?> getMyAgent() async {
    final symbol = await getAgentSymbol();
    if (symbol == null) {
      return null;
    }
    return getAgent(symbol: symbol);
  }

  /// Get the agent from the database.
  Future<Agent?> getAgent({required String symbol}) async {
    final query = agentBySymbolQuery(symbol);
    return queryOne(query, agentFromColumnMap);
  }

  /// Update the given agent in the database.
  Future<void> upsertAgent(Agent agent) async {
    await execute(upsertAgentQuery(agent));
  }

  /// Get the market listing for the given symbol.
  Future<MarketListing?> marketListingForSymbol(
    WaypointSymbol waypointSymbol,
  ) async {
    final query = marketListingByWaypointSymbolQuery(waypointSymbol);
    return queryOne(query, marketListingFromColumnMap);
  }

  /// Get all market listings.
  Future<Iterable<MarketListing>> allMarketListings() async {
    final query = allMarketListingsQuery();
    return queryMany(query, marketListingFromColumnMap);
  }

  /// Get all market listings within a system.
  Future<Iterable<MarketListing>> marketListingsInSystem(
    SystemSymbol system,
  ) async {
    final query = marketListingsInSystemQuery(system);
    return queryMany(query, marketListingFromColumnMap);
  }

  /// Get all WaypointSymbols with a market importing the given tradeSymbol.
  Future<Iterable<WaypointSymbol>> marketsWithImportInSystem(
    SystemSymbol system,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketsWithImportInSystemQuery(system, tradeSymbol);
    return queryMany(
      query,
      (map) => WaypointSymbol.fromString(map['symbol'] as String),
    );
  }

  /// Get all WaypointSymbols with a market importing the given tradeSymbol.
  Future<Iterable<WaypointSymbol>> marketsWithExportInSystem(
    SystemSymbol system,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketsWithExportInSystemQuery(system, tradeSymbol);
    return queryMany(
      query,
      (map) => WaypointSymbol.fromString(map['symbol'] as String),
    );
  }

  /// Returns true if we know of a market which trades the given symbol.
  Future<bool> knowOfMarketWhichTrades(TradeSymbol tradeSymbol) async {
    final query = knowOfMarketWhichTradesQuery(tradeSymbol);
    final result = await execute(query);
    return result[0][0]! as bool;
  }

  /// Update the given market listing in the database.
  Future<void> upsertMarketListing(MarketListing listing) async {
    await execute(upsertMarketListingQuery(listing));
  }

  /// Get the shipyard listing for the given symbol.
  Future<ShipyardListing?> shipyardListingForSymbol(
    WaypointSymbol waypointSymbol,
  ) async {
    final query = shipyardListingByWaypointSymbolQuery(waypointSymbol);
    return queryOne(query, shipyardListingFromColumnMap);
  }

  /// Get all shipyard listings.
  Future<Iterable<ShipyardListing>> allShipyardListings() async {
    final query = allShipyardListingsQuery();
    return queryMany(query, shipyardListingFromColumnMap);
  }

  /// Update the given shipyard listing in the database.
  Future<void> upsertShipyardListing(ShipyardListing listing) async {
    await execute(upsertShipyardListingQuery(listing));
  }

  /// Get unique ship symbols from the transaction table.
  Future<Set<ShipSymbol>> uniqueShipSymbolsInTransactions() async {
    final result = await executeSql(
      'SELECT DISTINCT ship_symbol FROM transaction_',
    );
    return result.map((r) => ShipSymbol.fromString(r.first! as String)).toSet();
  }

  /// Get all transactions from the database.
  /// Currently returns in timestamp order, but that may not always be the case.
  Future<Iterable<Transaction>> allTransactions() async {
    final result = await executeSql(
      'SELECT * FROM transaction_ ORDER BY timestamp',
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get all transactions matching accountingType from the database.
  Future<Iterable<Transaction>> transactionsWithAccountingType(
    AccountingType accountingType,
  ) async {
    final result = await execute(
      Query(
        'SELECT * FROM transaction_ WHERE '
        'accounting = @accounting',
        parameters: {'accounting': accountingType.name},
      ),
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get transactions after a given timestamp.
  /// Returned in ascending timestamp order.
  Future<Iterable<Transaction>> transactionsAfter(DateTime timestamp) async {
    final result = await execute(
      Query(
        'SELECT * FROM transaction_ WHERE timestamp > @timestamp '
        'ORDER BY timestamp',
        parameters: {'timestamp': timestamp},
      ),
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get the N most recent transactions.
  /// Returned in descending timestamp order.
  Future<Iterable<Transaction>> recentTransactions({required int count}) async {
    final result = await execute(
      Query(
        'SELECT * FROM transaction_ ORDER BY timestamp DESC LIMIT @count',
        parameters: {'count': count},
      ),
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get all market prices from the database.
  Future<Iterable<MarketPrice>> allMarketPrices() async {
    return queryMany(allMarketPricesQuery(), marketPriceFromColumnMap);
  }

  /// Get all market prices within the given system.
  Future<Iterable<MarketPrice>> marketPricesInSystem(
    SystemSymbol system,
  ) async {
    final query = marketPricesInSystemQuery(system);
    return queryMany(query, marketPriceFromColumnMap);
  }

  /// Add a market price to the database.
  Future<void> upsertMarketPrice(MarketPrice price) async {
    await execute(upsertMarketPriceQuery(price));
  }

  /// Get the market price for the given waypoint and trade symbol.
  Future<MarketPrice?> marketPriceAt(
    WaypointSymbol waypointSymbol,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketPriceQuery(waypointSymbol, tradeSymbol);
    return queryOne(query, marketPriceFromColumnMap);
  }

  /// Get the median purchase price for the given trade symbol.
  Future<int?> medianMarketPurchasePrice(TradeSymbol tradeSymbol) async {
    final query = medianMarketPurchasePriceQuery(tradeSymbol);
    final result = await execute(query);
    return result[0][0] as int?;
  }

  /// Get all shipyard prices from the database.
  Future<Iterable<ShipyardPrice>> allShipyardPrices() async {
    return queryMany(allShipyardPricesQuery(), shipyardPriceFromColumnMap);
  }

  /// Get the shipyard price for the given waypoint and ship type.
  Future<ShipyardPrice?> shipyardPriceAt(
    WaypointSymbol waypointSymbol,
    ShipType shipType,
  ) async {
    final query = shipyardPriceQuery(waypointSymbol, shipType);
    return queryOne(query, shipyardPriceFromColumnMap);
  }

  /// Add a shipyard price to the database.
  Future<void> upsertShipyardPrice(ShipyardPrice price) async {
    await execute(upsertShipyardPriceQuery(price));
  }

  /// Get all jump gates from the database.
  Future<Iterable<JumpGate>> allJumpGates() async {
    return queryMany(allJumpGatesQuery(), jumpGateFromColumnMap);
  }

  /// Add a jump gate to the database.
  Future<void> upsertJumpGate(JumpGate jumpGate) async {
    await execute(upsertJumpGateQuery(jumpGate));
  }

  /// Get the jump gate for the given waypoint symbol.
  Future<JumpGate?> getJumpGate(WaypointSymbol waypointSymbol) async {
    final query = getJumpGateQuery(waypointSymbol);
    return queryOne(query, jumpGateFromColumnMap);
  }

  /// Get all contracts from the database.
  Future<Iterable<Contract>> allContracts() async {
    return queryMany(allContractsQuery(), contractFromColumnMap);
  }

  /// Get a contract by id.
  Future<Contract?> contractById(String id) async {
    final query = contractByIdQuery(id);
    return queryOne(query, contractFromColumnMap);
  }

  /// Get all contracts which are !accepted.
  Future<Iterable<Contract>> unacceptedContracts() async {
    return queryMany(unacceptedContractsQuery(), contractFromColumnMap);
  }

  /// Get all contracts which are !fulfilled and !expired.
  Future<Iterable<Contract>> activeContracts() async {
    return queryMany(activeContractsQuery(), contractFromColumnMap);
  }

  /// Upsert a contract into the database.
  Future<void> upsertContract(Contract contract) async {
    await execute(upsertContractQuery(contract));
  }

  /// Get all behavior states.
  Future<Iterable<BehaviorState>> allBehaviorStates() async {
    return queryMany(allBehaviorStatesQuery(), behaviorStateFromColumnMap);
  }

  /// Get all behavior states with the given behavior.
  Future<Iterable<BehaviorState>> behaviorStatesWithBehavior(
    Behavior behavior,
  ) async {
    final query = behaviorStatesWithBehaviorQuery(behavior);
    return queryMany(query, behaviorStateFromColumnMap);
  }

  /// Get a behavior state by ship symbol.
  Future<BehaviorState?> behaviorStateBySymbol(ShipSymbol shipSymbol) async {
    final query = behaviorBySymbolQuery(shipSymbol);
    return queryOne(query, behaviorStateFromColumnMap);
  }

  /// Get a behavior state by symbol.
  Future<void> setBehaviorState(BehaviorState behaviorState) async {
    await execute(upsertBehaviorStateQuery(behaviorState));
  }

  /// Delete a behavior state.
  Future<void> deleteBehaviorState(ShipSymbol shipSymbol) async {
    await execute(deleteBehaviorStateQuery(shipSymbol));
  }

  /// Get all ships.
  Future<Iterable<Ship>> allShips() async {
    return queryMany(allShipsQuery(), shipFromColumnMap);
  }

  /// Get a ship by symbol.
  Future<Ship?> getShip(ShipSymbol symbol) async {
    final query = shipBySymbolQuery(symbol);
    return queryOne(query, shipFromColumnMap);
  }

  /// Upsert a ship into the database.
  Future<void> upsertShip(Ship ship) async {
    await execute(upsertShipQuery(ship));
  }

  /// Delete a ship from the database.
  Future<void> deleteShip(ShipSymbol symbol) async {
    await execute(deleteShipQuery(symbol));
  }

  Future<bool> _hasRecentPrice(Query query, Duration maxAge) async {
    final result = await execute(query);
    if (result.isEmpty) {
      return false;
    }
    final timestamp = result[0][0] as DateTime?;
    if (timestamp == null) {
      return false;
    }
    return DateTime.now().difference(timestamp) < maxAge;
  }

  /// Check if the given waypoint has recent market prices.
  Future<bool> hasRecentMarketPrices(
    WaypointSymbol waypointSymbol,
    Duration maxAge,
  ) async {
    final query = timestampOfMostRecentMarketPriceQuery(waypointSymbol);
    return _hasRecentPrice(query, maxAge);
  }

  /// Check if the given waypoint has recent shipyard prices.
  Future<bool> hasRecentShipyardPrices(
    WaypointSymbol waypointSymbol,
    Duration maxAge,
  ) async {
    final query = timestampOfMostRecentShipyardPriceQuery(waypointSymbol);
    return _hasRecentPrice(query, maxAge);
  }

  /// Count the number of market prices in the database.
  Future<int> marketPricesCount() async {
    final result = await executeSql('SELECT COUNT(*) FROM market_price_');
    return result[0][0]! as int;
  }

  /// Count the number of unique symbols in the MarketPrices table.
  Future<int> marketPricesWaypointCount() async {
    final result = await executeSql(
      'SELECT COUNT(DISTINCT waypoint_symbol) FROM market_price_',
    );
    return result[0][0]! as int;
  }

  /// Count the number of shipyard prices in the database.
  Future<int> shipyardPricesCount() async {
    final result = await executeSql('SELECT COUNT(*) FROM shipyard_price_');
    return result[0][0]! as int;
  }

  /// Count the number of unique symbols in the ShipyardPrices table.
  Future<int> shipyardPricesWaypointCount() async {
    final result = await executeSql(
      'SELECT COUNT(DISTINCT waypoint_symbol) FROM shipyard_price_',
    );
    return result[0][0]! as int;
  }

  /// Get my agent symbol from the config table in the db.
  Future<String?> getAgentSymbol() async {
    final result = await executeSql(
      "SELECT value FROM config_ WHERE key = 'agent_symbol'",
    );
    if (result.isEmpty) {
      return null;
    }
    return result[0][0]! as String;
  }

  /// Set my agent symbol in the config table in the db.
  Future<void> setAgentSymbol(String symbol) async {
    await executeSql(
      "INSERT INTO config_ (key, value) VALUES ('agent_symbol', "
      "'$symbol') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
    );
  }

  /// Get the game phase from the config table in the db.
  Future<GamePhase?> getGamePhase() async {
    final result = await executeSql(
      "SELECT value FROM config_ WHERE key = 'game_phase'",
    );
    if (result.isEmpty) {
      return null;
    }
    return GamePhase.fromJson(result[0][0]! as String);
  }

  /// Set the game phase in the config table in the db.
  Future<void> setGamePhase(GamePhase phase) async {
    await executeSql(
      "INSERT INTO config_ (key, value) VALUES ('game_phase', "
      "'${phase.toJson()}') "
      'ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value',
    );
  }

  /// Get the auth token from the config table in the db.
  Future<String?> getAuthToken() async {
    final result = await executeSql(
      "SELECT value FROM config_ WHERE key = 'auth_token'",
    );
    if (result.isEmpty) {
      return null;
    }
    return result[0][0]! as String;
  }

  /// Set the auth token in the config table in the db.
  Future<void> setAuthToken(String token) async {
    await executeSql(
      "INSERT INTO config_ (key, value) VALUES ('auth_token', "
      "'$token') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
    );
  }

  Future<Map<String, dynamic>?> getFromStaticCache({
    required Type type,
    required String key,
  }) async {
    final result = await queryOne(
      Query(
        'SELECT json FROM static_data_ WHERE type = @type AND key = @key',
        parameters: {'type': type.toString(), 'key': key},
      ),
      (map) => map['json'] as Map<String, dynamic>,
    );
    return result;
  }

  Future<Iterable<Map<String, dynamic>>> getAllFromStaticCache({
    required Type type,
  }) async {
    final result = await queryMany(
      Query(
        'SELECT json FROM static_data_ WHERE type = @type',
        parameters: {'type': type.toString()},
      ),
      (map) => map['json'] as Map<String, dynamic>,
    );
    return result;
  }

  Future<void> upsertInStaticCache({
    required Type type,
    required String key,
    required Map<String, dynamic> json,
    // Reset is intended to store which reset the data was created in.
    // But we've not wired it up yet.
    String reset = '1',
  }) async {
    await execute(
      Query(
        'INSERT INTO static_data_ (type, key, reset, json) '
        'VALUES (@type, @key, @reset, @json) '
        'ON CONFLICT (type, key) DO UPDATE SET json = EXCLUDED.json',
        parameters: {
          'type': type.toString(),
          'key': key,
          'json': json,
          'reset': reset,
        },
      ),
    );
  }
}
