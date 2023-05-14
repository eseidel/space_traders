import 'package:file/file.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/rate_limit.dart';

String loadAuthToken(FileSystem fs) {
  final token = fs.file('auth_token.txt').readAsStringSync().trim();
  if (token.isEmpty) {
    throw "No auth token found.";
  }
  return token;
}

Api apiFromAuthToken(String token) {
  final auth = HttpBearerAuth()..accessToken = token;
  return Api(RateLimitedApiClient(requestsPerSecond: 2, authentication: auth));
}

Api defaultApi(FileSystem fs) {
  return apiFromAuthToken(loadAuthToken(fs));
}

Future<String> loadAuthTokenOrRegister(FileSystem fs) async {
  try {
    return loadAuthToken(fs);
  } catch (e) {
    logger.info("No auth token found.");
    // Otherwise, register a new user.
    final handle = logger.prompt("What is your call sign?");
    final token = await register(handle);
    await fs.file('auth_token.txt').writeAsString(token);
    return token;
  }
}
