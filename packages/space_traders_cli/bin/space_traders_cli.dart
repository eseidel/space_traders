import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/logic.dart';

void main(List<String> arguments) async {
  logger.info("Welcome to Space Traders! 🚀");
  // Use package:file to make things mockable.
  var fs = const LocalFileSystem();
  var token = await loadAuthTokenOrRegister(fs);
  var api = apiFromAuthToken(token);
  logic(api);
}
