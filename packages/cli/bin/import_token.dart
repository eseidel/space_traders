import 'package:cli/cli.dart';
import 'package:file/local.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final token = argResults.rest.first;
  const fs = LocalFileSystem();
  final tokenFile = fs.file(token);
  if (!tokenFile.existsSync()) {
    logger.err('Token file does not exist: $token');
    return;
  }
  final tokenString = await tokenFile.readAsString();
  await db.config.setAuthToken(tokenString.trim());
  logger.info('Token imported successfully.');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
