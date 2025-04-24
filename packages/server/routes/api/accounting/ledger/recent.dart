import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  // TODO(eseidel): Read count from request, and paginate responses.
  final transactions = await db.recentTransactions(count: 10);
  final response = GetTransactionsResponse(
    transactions: transactions.toList(),
    // Does this need to be db time?
    timestamp: DateTime.timestamp(),
  );
  return Response.json(body: response.toJson());
}
