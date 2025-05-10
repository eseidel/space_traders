import 'dart:convert';

import 'package:cli/cli.dart';
import 'package:file/local.dart';

Future<void> command(Database db, ArgResults argResults) async {
  const fs = LocalFileSystem();
  final directory = fs.directory('static_data');
  if (!await directory.exists()) {
    logger.err('Directory does not exist: $directory');
    return;
  }

  // Walk all static caches and export them to the given directory.
  final pathToCache = <String, StaticStore>{
    'engines': db.shipEngines,
    'events': db.events,
    'exports': db.tradeExports,
    'modules': db.shipModules,
    'mounts': db.shipMounts,
    'reactors': db.shipReactors,
    'shipyard_ships': db.shipyardShips,
    'trade_goods': db.tradeGoods,
    'waypoint_traits': db.waypointTraits,
  };
  const encoder = JsonEncoder.withIndent(' ');

  for (final entry in pathToCache.entries) {
    final cacheName = entry.key;
    final cache = entry.value;
    final records = await cache.asSortedJsonList();
    final jsonString = encoder.convert(records);

    final filePath = '${directory.path}/$cacheName.json';
    final file = fs.file(filePath);
    await file.writeAsString(jsonString);
    logger.info('Exported $cacheName to $filePath');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
