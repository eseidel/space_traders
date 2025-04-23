import 'package:cli/accounting/balance_sheet.dart';
import 'package:cli/accounting/income_statement.dart';
import 'package:cli/caches.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();
  final fs = context.read<FileSystem>();

  final balanceSheet = await computeBalanceSheet(fs, db);
  final incomeStatement = await computeIncomeStatement(db);
  final response = AccountingSummaryResponse(
    balanceSheet: balanceSheet,
    incomeStatement: incomeStatement,
  );

  return Response.json(body: response.toJson());
}
