import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final contractCache = ContractCache.loadCached(fs)!;
  for (final contract in contractCache.contracts) {
    logger.info(contractDescription(contract));
    prettyPrintJson(contract.toJson());
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
