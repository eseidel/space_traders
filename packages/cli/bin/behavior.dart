import 'dart:convert';

import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults argResults) async {
  var behaviors = await db.behaviors.all();
  if (argResults.rest.isNotEmpty) {
    final onlyShips =
        argResults.rest.map((s) => int.parse(s, radix: 16)).toSet();
    behaviors =
        behaviors
            .where((b) => onlyShips.contains(b.shipSymbol.number))
            .toList();
  }
  if (behaviors.isEmpty) {
    logger.info('No behaviors found.');
    return;
  }

  final jsonList = behaviors.map((b) => b.toJson()).toList();
  const encoder = JsonEncoder.withIndent(' ');
  final prettyprint = encoder.convert(jsonList);
  logger.info(prettyprint);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
