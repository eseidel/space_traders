import 'package:cli/cache/contract_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/printing.dart';
import 'package:file/local.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final contractCache = await ContractCache.load(api);
  for (final contract in contractCache.contracts) {
    logger.info(contractDescription(contract));
    prettyPrintJson(contract.toJson());
  }
}
