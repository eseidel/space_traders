import 'dart:convert';

import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // Given a JSON file, reads it in and populates TradeExportCache from it.
  final exportCache = TradeExportCache.load(fs);
  final file = fs.file('exports.json');
  final json = jsonDecode(file.readAsStringSync());
  final exportsMap = json as Map<String, dynamic>;
  for (final exportName in exportsMap.keys) {
    final importsJson = exportsMap[exportName] as List<dynamic>;
    final export = TradeSymbol.fromJson(exportName)!;
    final imports = importsJson.map((i) => TradeSymbol.fromJson(i as String)!);
    exportCache.add(TradeExport(export: export, imports: imports.toList()));
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
