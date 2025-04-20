import 'package:cli/api.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

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
  Authentication? auth,
}) {
  final CountingApiClient apiClient;
  if (overrideBaseUrl != null) {
    apiClient = CountingApiClient(
      authentication: auth,
      basePath: overrideBaseUrl,
    );
  } else {
    apiClient = CountingApiClient(authentication: auth);
  }
  apiClient.client = getQueuedClient(db, getPriority: getPriority);
  return apiClient;
}

/// apiFromAuthToken creates an Api with the given auth token.
Api apiFromAuthToken(
  String token,
  Database db, {
  int Function() getPriority = defaultGetPriority,
  String? overrideBaseUrl,
}) {
  final auth = HttpBearerAuth()..accessToken = token;
  final apiClient = getApiClient(db, getPriority: getPriority, auth: auth);
  return Api(apiClient);
}

/// Waits for the auth token to be available and then creates an API.
Future<Api> waitForApi(
  Database db, {
  int Function() getPriority = defaultGetPriority,
}) async {
  var token = await db.getAuthToken();
  while (token == null) {
    await Future<void>.delayed(const Duration(minutes: 1));
    token = await db.getAuthToken();
  }
  return apiFromAuthToken(token, db, getPriority: getPriority);
}

/// defaultApi creates an Api with the default auth token read from the
/// given file system.
Future<Api> defaultApi(
  Database db, {
  int Function() getPriority = defaultGetPriority,
}) async {
  final token = await db.getAuthToken();
  if (token == null) {
    throw Exception('No auth token found.');
  }
  return apiFromAuthToken(token, db, getPriority: getPriority);
}
