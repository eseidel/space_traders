import 'package:cli/api.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';

export 'package:cli/net/queue.dart'
    show networkPriorityDefault, networkPriorityLow;

/// Default priority function.
int defaultGetPriority() => networkPriorityDefault;

/// Create a queued client with the given priority function.
QueuedClient getQueuedClient(
  Database db, {
  required int Function() getPriority,
}) {
  return QueuedClient(db)..getPriority = getPriority;
}

/// Create an API client with priority function.
CountingApiClient getApiClient(
  Database db, {
  int Function() getPriority = defaultGetPriority,
  String? overrideBaseUrl,
  Map<String, String>? defaultHeaders,
}) {
  return CountingApiClient(
    baseUri: overrideBaseUrl != null ? Uri.parse(overrideBaseUrl) : null,
    defaultHeaders: defaultHeaders ?? {},
    client: getQueuedClient(db, getPriority: getPriority),
  );
}

/// apiFromAuthToken creates an Api with the given auth token.
Api apiFromAuthToken(
  String token,
  Database db, {
  int Function() getPriority = defaultGetPriority,
}) {
  final defaultHeaders = <String, String>{'Authorization': 'Bearer $token'};
  final apiClient = getApiClient(
    db,
    getPriority: getPriority,
    defaultHeaders: defaultHeaders,
  );
  return Api(apiClient);
}

/// Waits for the auth token to be available and then creates an API.
Future<Api> waitForApi(
  Database db, {
  int Function() getPriority = defaultGetPriority,
}) async {
  var token = await db.config.getAuthToken();
  while (token == null) {
    await Future<void>.delayed(const Duration(minutes: 1));
    token = await db.config.getAuthToken();
  }
  return apiFromAuthToken(token, db, getPriority: getPriority);
}

/// defaultApi creates an Api with the default auth token read from the
/// given file system.
Future<Api> defaultApi(
  Database db, {
  int Function() getPriority = defaultGetPriority,
}) async {
  final token = await db.config.getAuthToken();
  if (token == null) {
    throw Exception('No auth token found.');
  }
  return apiFromAuthToken(token, db, getPriority: getPriority);
}
