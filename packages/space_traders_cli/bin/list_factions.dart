import 'dart:convert';

import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/cli.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/queries.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final factions = await getAllFactions(api).toList();
  final hqByFaction = <String, String>{
    for (final faction in factions) faction.name: faction.headquarters
  };
  logger.info(jsonEncode(hqByFaction));
}
