import 'package:cli/api.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/queue.dart';
import 'package:db/db.dart';
import 'package:file/file.dart';

export 'package:cli/net/queue.dart'
    show networkPriorityDefault, networkPriorityLow;

/// The default path to the auth token.
const String defaultAuthTokenPath = 'data/auth_token.txt';

/// loadAuthToken loads the auth token from the given file system or
/// throws an error if it cannot be found.
String loadAuthToken(FileSystem fs, {String path = defaultAuthTokenPath}) {
  final token = fs.file(path).readAsStringSync().trim();
  if (token.isEmpty) {
    throw Exception('No auth token found.');
  }
  return token;
}

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
    apiClient =
        CountingApiClient(authentication: auth, basePath: overrideBaseUrl);
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

/// defaultApi creates an Api with the default auth token read from the
/// given file system.
Api defaultApi(
  FileSystem fs,
  Database db, {
  int Function() getPriority = defaultGetPriority,
}) =>
    apiFromAuthToken(loadAuthToken(fs), db, getPriority: getPriority);
