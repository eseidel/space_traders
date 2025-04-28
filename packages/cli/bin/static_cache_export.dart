import 'dart:convert';

import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final staticCaches = StaticCaches(db);

  final directory = fs.directory('static_data');
  if (!await directory.exists()) {
    logger.err('Directory does not exist: $directory');
    return;
  }

  // Walk all static caches and export them to the given directory.
  final pathToCache = <String, StaticCache>{
    'engines': staticCaches.engines,
    'events': staticCaches.events,
    'exports': staticCaches.exports,
    'modules': staticCaches.modules,
    'mounts': staticCaches.mounts,
    'reactors': staticCaches.reactors,
    'shipyard_ships': staticCaches.shipyardShips,
    'trade_goods': staticCaches.tradeGoods,
    'waypoint_traits': staticCaches.waypointTraits,
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
