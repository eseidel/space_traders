import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';

Database? _db;

Middleware cachedDatabaseProvider() {
  return provider<Future<Database>>((context) async {
    _db ??= await defaultDatabase();
    return _db!;
  });
}

Handler middleware(Handler handler) {
  return handler.use(cachedDatabaseProvider());
}
