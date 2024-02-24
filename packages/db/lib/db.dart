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
      openConnection = _defaultOpenConnection,
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

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.endpoint, {this.settings});

  /// Create a new database with mock connection for testing.
  @visibleForTesting
  Database.test(this._connection)
      : endpoint = pg.Endpoint(host: 'localhost', database: 'test'),
        settings = null;

  /// The underlying connection.
  // TODO(eseidel): This shoudn't be public.
  // Make it private and move all callers into the db package.
  pg.Connection get connection => _connection;

  late final pg.Connection _connection;

  /// Configure the database connection.
  final pg.Endpoint endpoint;

  /// Configure the database connection.
  final pg.ConnectionSettings? settings;

  /// Open the database connection.
  Future<void> open({
    @visibleForTesting
    Future<pg.Connection> Function(
      pg.Endpoint endpoint,
      pg.ConnectionSettings? settings,
    ) openConnection = _defaultOpenConnection,
  }) async {
    _connection = await openConnection(endpoint, settings);
  }

  /// Close the database connection.
  Future<void> close() => connection.close();

  /// Listen for notifications on a channel.
  Future<void> listen(String channel) async {
    await connection.execute('LISTEN $channel');
  }

  /// Insert one record using the provided query.
  @protected
  Future<pg.Result> execute(Query query) {
    return connection.execute(
      pg.Sql.named(query.fmtString),
      parameters: query.parameters,
    );
  }

  /// Query for multiple records using the provided query.
  @protected
  Future<Iterable<T>> queryMany<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return connection
        .execute(
          pg.Sql.named(query.fmtString),
          parameters: query.parameters,
        )
        .then(
          (result) => result.map((r) => r.toColumnMap()).map(fromColumnMap),
        );
  }

  /// Query for a single record using the provided query.
  @protected
  Future<T?> queryOne<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return connection
        .execute(
          pg.Sql.named(query.fmtString),
          parameters: query.parameters,
        )
        .then(
          (result) =>
              result.isEmpty ? null : fromColumnMap(result.first.toColumnMap()),
        );
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
  Future<void> cacheFactions(List<Faction> factions) async {
    await connection.runTx((session) async {
      for (final faction in factions) {
        final query = insertFactionQuery(faction);
        await session.execute(
          pg.Sql.named(query.fmtString),
          parameters: query.parameters,
        );
      }
    });
  }

  /// Return all extractions.
  Future<Iterable<ExtractionRecord>> allExtractions() async =>
      queryMany(allExtractionsQuery(), extractionFromColumnMap);

  /// Insert an extraction into the database.
  Future<void> insertExtraction(ExtractionRecord extraction) async =>
      execute(insertExtractionQuery(extraction));

  /// Get a construction record from the database.
  Future<ConstructionRecord?> getConstruction(
    WaypointSymbol waypointSymbol,
    Duration maxAge,
  ) =>
      queryOne(
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
  ) =>
      queryOne(
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
    return connection.execute(
      pg.Sql.named('DELETE FROM response_ WHERE created_at < @timestamp'),
      parameters: {
        'timestamp': timestamp,
      },
    );
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
  Future<List<MarketListing>> allMarketListings() async {
    final query = allMarketListingsQuery();
    return queryMany(query, marketListingFromColumnMap)
        .then((list) => list.toList());
  }

  /// Get all WaypointSymbols with a market importing the given tradeSymbol.
  Future<List<WaypointSymbol>> marketsWithImportInSystem(
    SystemSymbol system,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketsWithImportInSystemQuery(system, tradeSymbol);
    return queryMany(
      query,
      (map) => WaypointSymbol.fromString(map['symbol'] as String),
    ).then((list) => list.toList());
  }

  /// Returns true if we know of a market which trades the given symbol.
  Future<bool> knowOfMarketWhichTrades(TradeSymbol tradeSymbol) async {
    final query = knowOfMarketWhichTradesQuery(tradeSymbol);
    final result = await connection.execute(
      pg.Sql.named(query.fmtString),
      parameters: query.parameters,
    );
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
  Future<List<ShipyardListing>> allShipyardListings() async {
    final query = allShipyardListingsQuery();
    return queryMany(query, shipyardListingFromColumnMap)
        .then((list) => list.toList());
  }

  /// Update the given shipyard listing in the database.
  Future<void> upsertShipyardListing(ShipyardListing listing) async {
    await execute(upsertShipyardListingQuery(listing));
  }

  /// Get unique ship symbols from the transaction table.
  Future<Set<ShipSymbol>> uniqueShipSymbolsInTransactions() async {
    final result = await connection
        .execute('SELECT DISTINCT ship_symbol FROM transaction_');
    return result.map((r) => ShipSymbol.fromString(r.first! as String)).toSet();
  }

  /// Get all transactions from the database.
  Future<Iterable<Transaction>> allTransactions() async {
    final result = await connection.execute('SELECT * FROM transaction_');
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get all transactions matching accountingType from the database.
  Future<Iterable<Transaction>> transactionsWithAccountingType(
    AccountingType accountingType,
  ) async {
    final result = await connection.execute(
      pg.Sql.named('SELECT * FROM transaction_ WHERE '
          'accounting = @accounting'),
      parameters: {'accounting': accountingType.name},
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get transactions after a given timestamp.
  Future<Iterable<Transaction>> transactionsAfter(
    DateTime timestamp,
  ) async {
    final result = await connection.execute(
      pg.Sql.named('SELECT * FROM transaction_ WHERE timestamp > @timestamp '
          'ORDER BY timestamp'),
      parameters: {'timestamp': timestamp},
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get all market prices from the database.
  Future<Iterable<MarketPrice>> allMarketPrices() async {
    return queryMany(allMarketPricesQuery(), marketPriceFromColumnMap);
  }

  /// Add a market price to the database.
  Future<void> upsertMarketPrice(MarketPrice price) async {
    await execute(upsertMarketPriceQuery(price));
  }

  /// Get all shipyard prices from the database.
  Future<Iterable<ShipyardPrice>> allShipyardPrices() async {
    return queryMany(allShipyardPricesQuery(), shipyardPriceFromColumnMap);
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

  /// Get all contracts which are !fullfilled and !expired.
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

  Future<bool> _hasRecentPrice(Query query, Duration maxAge) async {
    final result = await connection.execute(
      pg.Sql.named(query.fmtString),
      parameters: query.parameters,
    );
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
    final result =
        await connection.execute('SELECT COUNT(*) FROM market_price_');
    return result[0][0]! as int;
  }

  /// Count the number of unique symbols in the MarketPrices table.
  Future<int> marketPricesWaypointCount() async {
    final result = await connection.execute(
      'SELECT COUNT(DISTINCT waypoint_symbol) FROM market_price_',
    );
    return result[0][0]! as int;
  }

  /// Count the number of shipyard prices in the database.
  Future<int> shipyardPricesCount() async {
    final result =
        await connection.execute('SELECT COUNT(*) FROM shipyard_price_');
    return result[0][0]! as int;
  }

  /// Count the number of unique symbols in the ShipyardPrices table.
  Future<int> shipyardPricesWaypointCount() async {
    final result = await connection.execute(
      'SELECT COUNT(DISTINCT waypoint_symbol) FROM shipyard_price_',
    );
    return result[0][0]! as int;
  }
}
