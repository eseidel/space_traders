import 'dart:convert';

import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final factions = caches.factions.factions;
  final hqByFaction = <String, String>{
    for (final faction in factions) faction.name: faction.headquarters
  };
  logger.info(jsonEncode(hqByFaction));
}
