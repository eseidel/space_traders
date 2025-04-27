import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final token = argResults.rest.first;
  final tokenFile = fs.file(token);
  if (!tokenFile.existsSync()) {
    logger.err('Token file does not exist: $token');
    return;
  }
  final tokenString = await tokenFile.readAsString();
  await db.setAuthToken(tokenString.trim());
  logger.info('Token imported successfully.');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
