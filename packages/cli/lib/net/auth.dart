import 'dart:io';

import 'package:cli/api.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';

export 'package:cli/net/queue.dart'
    show networkPriorityDefault, networkPriorityLow;

/// Default priority function.
int defaultGetPriority() => networkPriorityDefault;

/// An api client that is authorized with an agent or account token.
class AuthorizedClient extends CountingApiClient {
  /// Construct an authorized client.
  AuthorizedClient({super.baseUri, super.client});

  /// The agent token.
  String? agentToken;

  /// The account token.
  String? accountToken;

  /// Get the secret from the client.
  String? getSecret(String name) {
    if (name == 'AgentToken') {
      return agentToken;
    }
    if (name == 'AccountToken') {
      return accountToken;
    }
    return null;
  }
}

/// Gets the base uri to use for the api client.
Future<Uri> determineBaseUri(Database db) async {
  // If we have an environment variable, return that.
  final baseUrlString = Platform.environment['ST_BASE_URL'];
  if (baseUrlString != null) {
    return Uri.parse(baseUrlString);
  }
  // Otherwise look up in the db config.
  final baseUrl = await db.global.getBaseUrl();
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
Future<AuthorizedClient> getApiClient(
  Database db, {
  required Uri baseUri,
  int Function() getPriority = defaultGetPriority,
}) async {
  return AuthorizedClient(
    client: getQueuedClient(db, getPriority: getPriority),
    baseUri: baseUri,
  );
}

/// apiFromAgentToken creates an Api with the given agent token.
Future<Api> apiFromAgentToken(
  String token,
  Database db, {
  required Uri baseUri,
  int Function() getPriority = defaultGetPriority,
}) async {
  final apiClient = await getApiClient(
    db,
    baseUri: baseUri,
    getPriority: getPriority,
  );
  apiClient.agentToken = token;
  return Api(apiClient);
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
  return apiFromAgentToken(
    token,
    db,
    getPriority: getPriority,
    baseUri: baseUri ?? await determineBaseUri(db),
  );
}
