import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scoped/scoped.dart';
import 'package:ui/route.dart';

const fs = LocalFileSystem();
late SystemsCache systemsCache;

void main() async {
  await runScoped(
    () async {
      systemsCache = await SystemsCache.load(fs, httpGet: http.get);
    },
    values: {loggerRef},
  );

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
