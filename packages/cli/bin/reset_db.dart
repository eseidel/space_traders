import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults args) async {
  logger.info('Resetting database');
  final db = await defaultDatabase();

  final token = await db.config.getAuthToken();
  final agentSymbol = await db.config.getAgentSymbol();
  logger.info('Migrating to schema 0');
  await db.migrateToSchema(version: 0);
  logger.info('Migrating to latest schema');
  await db.migrateToLatestSchema();
  logger.info('Setting config');

  if (token != null) {
    await db.config.setAuthToken(token);
  }
  if (agentSymbol != null) {
    await db.config.setAgentSymbol(agentSymbol);
  }
  logger.info('Done');
  await db.close();
}

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}
