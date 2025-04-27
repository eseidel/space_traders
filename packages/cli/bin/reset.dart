import 'package:cli/logger.dart';
import 'package:file/local.dart';

void main() {
  final logger = Logger();
  final now = DateTime.now();
  final nowString = '${now.year}-${now.month}-${now.day}';

  const fs = LocalFileSystem();
  fs.directory('backups').createSync();
  logger.info('mv data backups/data-$nowString');
  fs.directory('data').renameSync('backups/data-$nowString');
}
