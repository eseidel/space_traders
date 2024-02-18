import 'package:db/config.dart';
import 'package:db/src/agent.dart';
import 'package:db/src/chart.dart';
import 'package:db/src/construction.dart';
import 'package:db/src/extraction.dart';
import 'package:db/src/faction.dart';
import 'package:db/src/market_listing.dart';
import 'package:db/src/query.dart';
import 'package:db/src/queue.dart';
import 'package:db/src/shipyard_listing.dart';
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
  Future<pg.Connection> Function(pg.Endpoint endpoint) openConnection =
      _defaultOpenConnection,
}) async {
  final db = Database(defaultDatabaseEndpoint);
  await db.open(openConnection: openConnection);
  return db;
}

Future<pg.Connection> _defaultOpenConnection(pg.Endpoint endpoint) {
  return pg.Connection.open(endpoint);
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.endpoint);

  /// Create a new database with mock connection for testing.
  @visibleForTesting
  Database.test(this._connection)
      : endpoint = pg.Endpoint(host: 'localhost', database: 'test');

  /// The underlying connection.
  // TODO(eseidel): This shoudn't be public.
  // Make it private and move all callers into the db package.
  pg.Connection get connection => _connection;

  late final pg.Connection _connection;

  /// Configure the database connection.
  final pg.Endpoint endpoint;

  /// Open the database connection.
  Future<void> open({
    @visibleForTesting
    Future<pg.Connection> Function(pg.Endpoint endpoint) openConnection =
        _defaultOpenConnection,
  }) async {
    _connection = await openConnection(endpoint);
  }

  /// Close the database connection.
  Future<void> close() => connection.close();

  /// Listen for notifications on a channel.
  Future<void> listen(String channel) async {
    await connection.execute('LISTEN $channel');
  }

  /// Insert one record using the provided query.
  @protected
  Future<void> insertOne(Query query) {
    return connection.execute(
      query.fmtString,
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
          query.fmtString,
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
          query.fmtString,
          parameters: query.parameters,
        )
        .then(
          (result) =>
              result.isEmpty ? null : fromColumnMap(result.first.toColumnMap()),
        );
  }

  /// Insert a transaction into the database.
  Future<void> insertTransaction(Transaction transaction) async {
    await insertOne(insertTransactionQuery(transaction));
  }

  /// Insert a survey into the database.
  Future<void> insertSurvey(HistoricalSurvey survey) async {
    await insertOne(insertSurveyQuery(survey));
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
    final result = await connection.execute(
      query.fmtString,
      parameters: query.parameters,
    );
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
          query.fmtString,
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
      insertOne(insertExtractionQuery(extraction));

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
      insertOne(upsertConstructionQuery(record));

  /// Return all charting records.
  Future<Iterable<ChartingRecord>> allChartingRecords() async =>
      queryMany(allChartingRecordsQuery(), chartingRecordFromColumnMap);

  /// Insert a charting record into the database.
  Future<void> upsertChartingRecord(ChartingRecord record) async =>
      insertOne(upsertChartingRecordQuery(record));

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
    final result = await connection.execute(
      query.fmtString,
      parameters: query.parameters,
    );
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
    final result = await connection.execute(
      query.fmtString,
      parameters: query.parameters,
    );
    if (result.affectedRows != 1) {
      throw ArgumentError('Request not found: $request');
    }
  }

  /// Insert the given response into the database.
  Future<void> insertResponse(ResponseRecord response) async {
    await insertOne(insertResponseQuery(response));
  }

  /// Get the response with the given id.
  Future<ResponseRecord?> getResponseForRequest(int requestId) async {
    final query = getResponseForRequestQuery(requestId);
    return queryOne(query, responseRecordFromColumnMap);
  }

  /// Get the agent from the database.
  Future<Agent?> getAgent({required String symbol}) async {
    final query = agentBySymbolQuery(symbol);
    return queryOne(query, agentFromColumnMap);
  }

  /// Update the given agent in the database.
  Future<void> upsertAgent(Agent agent) async {
    final query = upsertAgentQuery(agent);
    await insertOne(query);
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

  /// Update the given market listing in the database.
  Future<void> upsertMarketListing(MarketListing listing) async {
    final query = upsertMarketListingQuery(listing);
    await insertOne(query);
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
    final query = upsertShipyardListingQuery(listing);
    await insertOne(query);
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
      'SELECT * FROM transaction_ WHERE '
      'accounting = @accounting',
      parameters: {'accounting': accountingType.name},
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get transactions after a given timestamp.
  Future<Iterable<Transaction>> transactionsAfter(
    DateTime timestamp,
  ) async {
    final result = await connection.execute(
      'SELECT * FROM transaction_ WHERE timestamp > @timestamp '
      'ORDER BY timestamp',
      parameters: {'timestamp': timestamp},
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }
}
