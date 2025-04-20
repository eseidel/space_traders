import 'package:cli/logger.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

Database? _db;

Logger? _logger;

Middleware cachedDatabaseProvider() {
  return provider<Future<Database>>((context) async {
    _db ??= await defaultDatabase();
    return _db!;
  });
}

Middleware filesystemProvider() {
  return provider<FileSystem>((context) {
    return const LocalFileSystem();
  });
}

Middleware loggerProvider() {
  return provider<Logger>((context) {
    _logger ??= Logger();
    return _logger!;
  });
}

Handler middleware(Handler handler) {
  return handler
      .use(cachedDatabaseProvider())
      .use(filesystemProvider())
      .use(loggerProvider());
}
