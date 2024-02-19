import 'dart:convert';

import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scoped/scoped.dart';
import 'package:types/api.dart';
import 'package:ui/route.dart';

const fs = LocalFileSystem();
late SystemsCache systemsCache;
late ShipSnapshot shipCache;

const shipsUrl = 'http://localhost:8080/ships';

Future<ShipSnapshot> loadShips() async {
  final response = await http.get(Uri.parse(shipsUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to load ships');
  }
  final ships = (jsonDecode(response.body) as List)
      .map((e) => Ship.fromJson(e as Map<String, dynamic>)!)
      .toList();
  return ShipSnapshot(ships);
}

void main() async {
  await runScoped(
    () async {
      systemsCache = await SystemsCache.loadOrFetch(fs);
    },
    values: {loggerRef},
  );
  shipCache = await loadShips();

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
