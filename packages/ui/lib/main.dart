import 'dart:io';

import 'package:cli/api.dart';
import 'package:cli/cache/faction_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scoped/scoped.dart';
import 'package:ui/route.dart';

const fs = LocalFileSystem();
late SystemsCache systemsCache;
late ShipCache shipCache;
late FactionCache factionCache;
final factionSystems = factionCache.factions
    .map((f) => WaypointSymbol.fromString(f.headquarters).system)
    .toSet();

const shipsUrl = 'http://localhost:8080/ships';

Future<ShipCache> loadShips() async {
  final cached = ShipCache.loadCached(fs);
  if (cached != null) {
    return cached;
  }
  final response = await http.get(Uri.parse(shipsUrl));
  File(ShipCache.defaultPath).writeAsBytesSync(response.bodyBytes);
  return ShipCache.loadCached(fs)!;
}

void main() async {
  await runScoped(
    () async {
      systemsCache = await SystemsCache.load(fs);
    },
    values: {loggerRef},
  );
  shipCache = await loadShips();
  factionCache = await FactionCache.loadUnauthenticated(fs);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}
