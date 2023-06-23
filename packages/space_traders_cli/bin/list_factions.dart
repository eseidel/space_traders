import 'dart:convert';

import 'package:file/local.dart';
import 'package:scoped/scoped.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/net/queries.dart';

Future<void> cliMain() async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final factions = await getAllFactions(api).toList();
  final hqByFaction = <String, String>{
    for (final faction in factions) faction.name: faction.headquarters
  };
  logger.info(jsonEncode(hqByFaction));
}

void main(List<String> args) async {
  await runScoped(cliMain, values: {loggerRef});
}
