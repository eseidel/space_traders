import 'dart:convert';

import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final api = await defaultApi(db, getPriority: () => networkPriorityLow);
  final response = await api.data.getSupplyChain();

  // Build the old-style TradeExport list from the response.
  final exports = <TradeExport>[];
  for (final entry in response!.data.exportToImportMap.entries) {
    final export = TradeSymbol.fromJson(entry.key);
    if (export == null) {
      continue;
    }
    final imports = entry.value.map((i) => TradeSymbol.fromJson(i)!);
    exports.add(TradeExport(export: export, imports: imports.toList()));
  }
  final traits = TradeExportSnapshot([]);
  exports.sort(traits.compare);
  const encoder = JsonEncoder.withIndent(' ');
  final json = encoder.convert(exports.map((e) => e.toJson()).toList());
  fs.file('static_data/exports.json').writeAsStringSync(json);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
