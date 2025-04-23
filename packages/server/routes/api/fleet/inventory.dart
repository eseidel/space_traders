import 'package:cli/accounting/balance_sheet.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:server/read_async.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  final inventory = await computeInventoryValue(db: db);
  return Response.json(body: inventory.toJson());
}
