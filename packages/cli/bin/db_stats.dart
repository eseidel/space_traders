import 'package:cli/cli.dart';
import 'package:db/db.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final db = await defaultDatabase();

  final connection = db.connection;
  // Get a list of all tables.
  final tables = await connection.query('''
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name;
  ''');
  // Get counts for each table.
  final counts = <String, int>{};
  for (final table in tables) {
    final tableName = table[0] as String;
    final count = await connection.query(
      'SELECT COUNT(*) FROM $tableName;',
    );
    counts[tableName] = count[0][0] as int;
  }
  // Print the counts.
  for (final tableName in counts.keys) {
    logger.info('$tableName: ${counts[tableName]}');
  }
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
