import 'dart:io';

import 'package:cli/cli.dart';
import 'package:file/local.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final tokenPath = argResults.rest.first;
  if (tokenPath.isEmpty) {
    logger.err('Token path required');
    return;
  }
  final String tokenString;
  if (tokenPath == '-') {
    tokenString = stdin.readLineSync() ?? '';
    if (tokenString.isEmpty) {
      logger.err('Token required');
      return;
    }
  } else {
    const fs = LocalFileSystem();
    final tokenFile = fs.file(tokenPath);
    if (!tokenFile.existsSync()) {
      logger.err('Token file does not exist: $tokenPath');
      return;
    }
    tokenString = await tokenFile.readAsString();
  }

  await db.config.setAuthToken(tokenString.trim());
  logger.info('Token imported successfully.');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
