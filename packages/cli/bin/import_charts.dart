import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final fileCache = OldChartingCache.load(fs);
  logger.info('Adding ${fileCache.records.length} file records.');
  for (final record in fileCache.records) {
    await db.upsertChartingRecord(record);
  }
  final allRecords = await db.allChartingRecords();
  logger.info('Now have ${allRecords.length} database records.');

  final waypointSymbols = allRecords.map((e) => e.waypointSymbol).toSet();
  logger.info('Have ${waypointSymbols.length} unique waypoint symbols.');

  // required or main() will hang
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}