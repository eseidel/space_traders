import 'package:file/local.dart';
import 'package:space_traders_cli/logger.dart';

void main() {
  // Get current date
  final now = DateTime.now();
  // Get current date as string
  final nowString = '${now.year}-${now.month}-${now.day}';

  final fileNames = [
    'datastore.json',
    'systems.json',
    'surveys.json',
    'prices.json',
    'auth_token.txt',
  ];
  const fs = LocalFileSystem();

  // make dir the nowString
  fs.directory(nowString).createSync();
  // move datastore.json to datastore-${nowString}.json\
  for (final fileName in fileNames) {
    try {
      fs.file(fileName).renameSync('nowString/$fileName');
    } catch (e) {
      logger.err(e.toString());
    }
  }
}
