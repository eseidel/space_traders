import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // Get a list of all tables.
  final tableNames = await db.allTableNames();
  // Get counts for each table.
  final counts = <String, int>{};
  for (final name in tableNames) {
    counts[name] = await db.rowsInTable(name);
  }
  // Print the counts.
  for (final tableName in counts.keys) {
    logger.info('$tableName: ${counts[tableName]}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
