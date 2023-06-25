import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/printing.dart';
import 'package:file/local.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final response = await api.contracts.getContracts();
  final contracts = response!.data;
  for (final contract in contracts) {
    logger.info(contractDescription(contract));
    prettyPrintJson(contract.toJson());
  }
}
