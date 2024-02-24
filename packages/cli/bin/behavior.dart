import 'dart:convert';

import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  var behaviors = await db.allBehaviorStates();
  if (argResults.rest.isNotEmpty) {
    final onlyShips =
        argResults.rest.map((s) => int.parse(s, radix: 16)).toSet();
    behaviors = behaviors
        .where((b) => onlyShips.contains(b.shipSymbol.number))
        .toList();
  }
  if (behaviors.isEmpty) {
    print('No behaviors found.');
    return;
  }

  final jsonList = behaviors.map((b) => b.toJson()).toList();
  const encoder = JsonEncoder.withIndent(' ');
  final prettyprint = encoder.convert(jsonList);
  print(prettyprint);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
