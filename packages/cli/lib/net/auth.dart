import 'dart:io';

import 'package:cli/api.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';

export 'package:cli/net/queue.dart'
    show networkPriorityDefault, networkPriorityLow;

/// Default priority function.
int defaultGetPriority() => networkPriorityDefault;

/// Gets the base uri to use for the api client.
Future<Uri> determineBaseUri(Database db) async {
  // If we have an environment variable, return that.
  final baseUrlString = Platform.environment['ST_BASE_URL'];
  if (baseUrlString != null) {
    return Uri.parse(baseUrlString);
  }
  // Otherwise look up in the db config.
  final baseUrl = await db.config.getBaseUrl();
  if (baseUrl != null) {
    return baseUrl;
  }
  // Otherwise, return the default.
  return Uri.parse('https://api.spacetraders.io/v2/');
}

/// Create a queued client with the given priority function.
QueuedClient getQueuedClient(
  Database db, {
  required int Function() getPriority,
}) {
  return QueuedClient(db)..getPriority = getPriority;
}

/// Create an API client with priority function.
Future<CountingApiClient> getApiClient(
  Database db, {
  required Uri baseUri,
  int Function() getPriority = defaultGetPriority,
  Map<String, String>? defaultHeaders,
}) async {
  return CountingApiClient(
    defaultHeaders: defaultHeaders ?? {},
    client: getQueuedClient(db, getPriority: getPriority),
    baseUri: baseUri,
  );
}

/// apiFromAuthToken creates an Api with the given auth token.
Future<Api> apiFromAuthToken(
  String token,
  Database db, {
  required Uri baseUri,
  int Function() getPriority = defaultGetPriority,
}) async {
  final defaultHeaders = <String, String>{'Authorization': 'Bearer $token'};
  final apiClient = await getApiClient(
    db,
    getPriority: getPriority,
    defaultHeaders: defaultHeaders,
    baseUri: baseUri,
  );
  return Api(apiClient);
}

/// Waits for the auth token to be available and then creates an API.
Future<Api> waitForApi(
  Database db, {
  required Uri baseUri,
  int Function() getPriority = defaultGetPriority,
}) async {
  var token = await db.config.getAgentToken();
  while (token == null) {
    await Future<void>.delayed(const Duration(minutes: 1));
    token = await db.config.getAgentToken();
  }
  return apiFromAuthToken(
    token,
    db,
    getPriority: getPriority,
    baseUri: baseUri,
  );
}

/// defaultApi creates an Api with the default auth token read from the
/// given file system.
Future<Api> defaultApi(
  Database db, {
  Uri? baseUri,
  int Function() getPriority = defaultGetPriority,
}) async {
  final token = await db.config.getAgentToken();
  if (token == null) {
    throw Exception('No auth token found.');
  }
  return apiFromAuthToken(
    token,
    db,
    getPriority: getPriority,
    baseUri: baseUri ?? await determineBaseUri(db),
  );
}
