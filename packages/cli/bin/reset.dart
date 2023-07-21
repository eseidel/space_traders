import 'package:file/local.dart';

void main() {
  final now = DateTime.now();
  final nowString = '${now.year}-${now.month}-${now.day}';

  const fs = LocalFileSystem();
  fs.directory('backups').createSync();
  fs.directory('data').renameSync('backups/data-$nowString');
}
