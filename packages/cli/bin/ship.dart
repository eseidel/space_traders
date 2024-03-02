import 'dart:convert';

import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  var ships = await db.allShips();
  if (argResults.rest.isNotEmpty) {
    final onlyShips =
        argResults.rest.map((s) => int.parse(s, radix: 16)).toSet();
    ships =
        ships.where((b) => onlyShips.contains(b.shipSymbol.number)).toList();
  }
  if (ships.isEmpty) {
    logger.info('No ships found.');
    return;
  }

  final jsonList = ships.map((b) => b.toJson()).toList();
  const encoder = JsonEncoder.withIndent(' ');
  final prettyprint = encoder.convert(jsonList);
  logger.info(prettyprint);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
